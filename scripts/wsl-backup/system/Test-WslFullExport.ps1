#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SeedArchive
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$seed = (Resolve-Path -LiteralPath $SeedArchive).Path
$token = [guid]::NewGuid().ToString('N')
$state = Join-Path $env:LOCALAPPDATA "WslFullExportTests\$token"
New-Item -ItemType Directory -Path $state | Out-Null
$sourceName = "FullExportTest-$token"
$restoreName = "FullRestoreTest-$token"
$transport = Join-Path $env:USERPROFILE 'git/agent-skills/skills/windows-env/Invoke-WslExec.ps1'
$volume = Get-Volume -DriveLetter $state.Substring(0, 1)
$partition = Get-Partition -DriveLetter $state.Substring(0, 1)
$disk = Get-Disk -Number $partition.DiskNumber
$exportScript = Join-Path $PSScriptRoot 'Export-WslFullBackup.ps1'
$exportDirectory = Join-Path $state 'exports'
$stdoutPath = Join-Path $state 'export.stdout.log'
$stderrPath = Join-Path $state 'export.stderr.log'

# Enlarge a copied seed on Windows so the fixture never needs Debian4.
$augmentedSeed = Join-Path $state 'seed-with-export-load.tar'
Copy-Item -LiteralPath $seed -Destination $augmentedSeed
$loadRoot = Join-Path $state 'load'
$loadDirectory = Join-Path $loadRoot 'var/tmp'
New-Item -ItemType Directory -Path $loadDirectory -Force | Out-Null
$loadPath = Join-Path $loadDirectory 'export-lock-fixture.bin'
$random = [Security.Cryptography.RandomNumberGenerator]::Create()
$loadStream = [IO.File]::Create($loadPath)
try {
    $buffer = [byte[]]::new(1MB)
    foreach ($block in 1..256) {
        $random.GetBytes($buffer)
        $loadStream.Write($buffer, 0, $buffer.Length)
    }
} finally {
    $loadStream.Dispose()
    $random.Dispose()
}
& tar.exe -rf $augmentedSeed -C $loadRoot 'var/tmp/export-lock-fixture.bin'
if ($LASTEXITCODE -ne 0) { throw 'Could not augment the synthetic seed archive' }

& wsl.exe --import $sourceName (Join-Path $state 'source') $augmentedSeed --version 2
if ($LASTEXITCODE -ne 0) { throw 'Synthetic source import failed' }
# Import can leave a service-side VHDX handle even though the distro never
# booted. Release every WSL handle before testing the coordinator's lock.
& wsl.exe --shutdown
if ($LASTEXITCODE -ne 0) { throw 'Fixture pre-export WSL shutdown failed' }
$runningAfterShutdown = @(& wsl.exe --list --running --quiet | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
if ($runningAfterShutdown.Count -ne 0) { throw 'A distro remained running after fixture pre-export shutdown' }

$startInfo = [Diagnostics.ProcessStartInfo]::new('pwsh.exe')
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
foreach ($argument in @(
    '-NoLogo', '-NoProfile', '-NonInteractive', '-File', $exportScript,
    '-Distro', $sourceName, '-OutputDirectory', $exportDirectory,
    '-ExpectedVolumeUniqueId', $volume.UniqueId, '-ExpectedDiskUniqueId', $disk.UniqueId
)) { $startInfo.ArgumentList.Add($argument) }
$exportProcess = [Diagnostics.Process]::Start($startInfo)
$stdoutTask = $exportProcess.StandardOutput.ReadToEndAsync()
$stderrTask = $exportProcess.StandardError.ReadToEndAsync()

$deadline = [DateTime]::UtcNow.AddSeconds(30)
do {
    Start-Sleep -Milliseconds 100
    $partialArchive = @(Get-ChildItem $exportDirectory -Filter rootfs.tar.gz -Recurse -ErrorAction SilentlyContinue)
} while (-not $partialArchive -and -not $exportProcess.HasExited -and [DateTime]::UtcNow -lt $deadline)
if (-not $partialArchive -or $exportProcess.HasExited) {
    if (-not $exportProcess.HasExited) { $exportProcess.Kill($true) }
    $exportProcess.WaitForExit()
    Set-Content -LiteralPath $stdoutPath -Value $stdoutTask.GetAwaiter().GetResult() -Encoding utf8NoBOM
    Set-Content -LiteralPath $stderrPath -Value $stderrTask.GetAwaiter().GetResult() -Encoding utf8NoBOM
    throw "Could not observe an active native export for the concurrency test; inspect $stderrPath"
}

& wsl.exe --distribution $sourceName --exec /bin/true 2>$null
$concurrentStartExit = $LASTEXITCODE
$stillExporting = -not $exportProcess.HasExited
if (-not $stillExporting) { throw 'Export ended during the concurrency probe; result is inconclusive' }
if ($concurrentStartExit -eq 0) { throw 'WSL allowed the source distro to start during export' }

$exportProcess.WaitForExit()
$stdout = $stdoutTask.GetAwaiter().GetResult()
$stderr = $stderrTask.GetAwaiter().GetResult()
Set-Content -LiteralPath $stdoutPath -Value $stdout -Encoding utf8NoBOM
Set-Content -LiteralPath $stderrPath -Value $stderr -Encoding utf8NoBOM
if ($exportProcess.ExitCode -ne 0) { throw "Synthetic export failed; inspect $stderrPath" }
if ($sourceName -in @(& wsl.exe --list --running --quiet | ForEach-Object { ($_ -replace "`0", '').Trim() })) {
    throw 'Synthetic source was left running after export'
}

$generation = @(Get-ChildItem $exportDirectory -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'manifest.json')
})
if ($generation.Count -ne 1) { throw 'Expected one completed generation' }
$archive = Join-Path $generation[0].FullName 'rootfs.tar.gz'
$manifest = Get-Content (Join-Path $generation[0].FullName 'manifest.json') -Raw | ConvertFrom-Json
# Registration leaves the stopped clone attached while the WSL VM is active.
# Detach it before independently hashing the retained VHDX.
& wsl.exe --shutdown
if ($LASTEXITCODE -ne 0) { throw 'Fixture post-export WSL shutdown failed' }
$sourceVhdHash = (Get-FileHash -LiteralPath (Join-Path $state 'source/ext4.vhdx') -Algorithm SHA256).Hash.ToLowerInvariant()
if ($manifest.schemaVersion -ne 3 -or
    $manifest.captureMethod -ne 'exclusive-cold-vhdx-copy-then-wsl-export' -or
    $manifest.sourceVhdxSha256 -ne $sourceVhdHash -or
    $manifest.coldCloneVhdxSha256BeforeRegistration -ne $sourceVhdHash -or
    $manifest.sha256 -ne (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -or
    $manifest.exclusions.Count -ne 0 -or
    $manifest.storage.volumeUniqueId -ne $volume.UniqueId -or
    $manifest.storage.diskUniqueId -ne $disk.UniqueId) {
    throw 'Manifest or storage identity mismatch'
}

& wsl.exe --import $restoreName (Join-Path $state 'restored') $archive --version 2
if ($LASTEXITCODE -ne 0) { throw 'Compressed import failed' }
try {
    $verify = @'
set -euo pipefail
IFS= read -r home </home/jack/fixture
IFS= read -r repository </var/lib/restic/home/config
IFS= read -r staging </var/tmp/fixture
[[ $home == home-included && $repository == repository-included && $staging == staging-included ]]
printf 'full_export_import_boot=passed home=true repository=true staging=true concurrency=passed\n'
'@
    & $transport -Distribution $restoreName -Script $verify
    if ($LASTEXITCODE -ne 0) { throw 'Synthetic restored boot/content verification failed' }
} finally {
    & wsl.exe --terminate $restoreName
    if ($LASTEXITCODE -ne 0) { throw 'Fixture stop failed' }
}
Write-Output "retained_fixture=$state source=$sourceName clone=$($manifest.captureCloneDistro) restored=$restoreName"
