#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$SourceDistribution,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z_][A-Za-z0-9_-]{0,31}$')]
    [string]$SourceUser,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$TargetDistribution,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z_][A-Za-z0-9_-]{0,31}$')]
    [string]$TargetUser,

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($SourceDistribution -eq $TargetDistribution) {
    throw 'Source and target distributions must differ.'
}

$MigrationScript = Join-Path $PSScriptRoot 'migrate-ak-secrets.sh'
if (-not (Test-Path -LiteralPath $MigrationScript -PathType Leaf)) {
    throw "Migration helper is missing: $MigrationScript"
}
$WslExecutable = Join-Path $env:WINDIR 'System32\wsl.exe'
if (-not (Test-Path -LiteralPath $WslExecutable -PathType Leaf)) {
    throw "System WSL executable is missing: $WslExecutable"
}

Write-Output 'AK/GnuPG secret migration plan:'
Write-Output "  source: $SourceDistribution ($SourceUser)"
Write-Output "  target: $TargetDistribution ($TargetUser)"
Write-Output '  content: GnuPG private keyring/config, AK routing config, encrypted ~/git/ak/secrets, and .gpg-key-id only'
Write-Output '  excluded: SSH keys, history, plaintext values, agent sockets, and all other home data'
Write-Output '  transport: direct native byte stream; no archive is written to Windows'
Write-Output '  target: existing allowlisted state is backed up before replacement'
if (-not $Execute) {
    Write-Output 'Preview only. Re-run with -Execute after checking both distribution and user names.'
    return
}

function Get-WslScriptPath {
    param([string]$Distribution, [string]$WindowsPath)
    $output = & wsl.exe --distribution $Distribution --exec wslpath -a $WindowsPath
    if ($LASTEXITCODE -ne 0) { throw "Could not map the helper path in $Distribution." }
    $path = ($output | Out-String).Trim()
    if (-not $path.StartsWith('/')) { throw "Invalid WSL helper path returned by $Distribution." }
    return $path
}

function Invoke-WslPipeProcess {
    param([string[]]$Arguments, [bool]$RedirectInput)
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $WslExecutable
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $RedirectInput
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { [void]$start.ArgumentList.Add($argument) }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $start
    if (-not $process.Start()) { throw 'Failed to start wsl.exe.' }
    return $process
}

$sourceScript = Get-WslScriptPath -Distribution $SourceDistribution -WindowsPath $MigrationScript
$targetScript = Get-WslScriptPath -Distribution $TargetDistribution -WindowsPath $MigrationScript
$target = $null
$source = $null
try {
    $target = Invoke-WslPipeProcess -RedirectInput $true -Arguments @('--distribution', $TargetDistribution, '--user', $TargetUser, '--exec', 'env', "AK_TARGET_DISTRIBUTION=$TargetDistribution", 'bash', $targetScript, 'import', '--execute')
    $targetOutputTask = $target.StandardOutput.ReadToEndAsync()
    $targetErrorTask = $target.StandardError.ReadToEndAsync()
    $source = Invoke-WslPipeProcess -RedirectInput $false -Arguments @('--distribution', $SourceDistribution, '--user', $SourceUser, '--exec', 'bash', $sourceScript, 'export')
    $sourceErrorTask = $source.StandardError.ReadToEndAsync()

    $source.StandardOutput.BaseStream.CopyTo($target.StandardInput.BaseStream)
    $target.StandardInput.Close()
    $source.WaitForExit()
    $target.WaitForExit()
    $sourceError = $sourceErrorTask.GetAwaiter().GetResult()
    $targetError = $targetErrorTask.GetAwaiter().GetResult()
    $targetOutput = $targetOutputTask.GetAwaiter().GetResult()
    if ($source.ExitCode -ne 0) { throw "Source export failed: $sourceError" }
    if ($target.ExitCode -ne 0) { throw "Target import failed: $targetError" }
    if ($targetError) { Write-Warning $targetError.Trim() }
    Write-Output $targetOutput.Trim()
    Write-Output 'Migration structure verified. Complete a passphrase-based check in the target, for example: ak get brave >/dev/null'
}
finally {
    foreach ($process in @($source, $target)) {
        if ($null -ne $process) {
            if (-not $process.HasExited) { $process.Kill($true) }
            $process.Dispose()
        }
    }
}
