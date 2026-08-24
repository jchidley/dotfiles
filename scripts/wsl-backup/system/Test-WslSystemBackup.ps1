$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run this script with the built-in Windows PowerShell (powershell.exe), not pwsh.'
}
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'WslSystemBackup.Common.ps1')

$tests = 0
function Assert-True {
    param([bool] $Condition, [string] $Message)
    $script:tests++
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}
function Expect-Throw {
    param([scriptblock] $Action, [string] $Pattern)
    $script:tests++
    $missing = "Expected action to throw pattern: $Pattern"
    try { & $Action; throw $missing }
    catch {
        if ($_.Exception.Message -eq $missing) { throw }
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "Unexpected error '$($_.Exception.Message)', expected '$Pattern'"
        }
    }
}

$root = Join-Path $env:TEMP ('wsl-system-backup-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    Assert-True ((Convert-ToWslPath 'C:\Users\Test User\file.txt') -eq '/mnt/c/Users/Test User/file.txt') 'Windows path conversion'
    Expect-Throw { Convert-ToWslPath '\\server\share\file' } 'not on a Windows drive'
    $activeExportProcesses = { @([pscustomobject]@{CommandLine='wsl.exe --export Debian-Recovered C:\backup.tar.gz --format tar.gz'}) }
    Assert-True (Test-ExportClientActive -Distro 'Debian-Recovered' -GetProcesses $activeExportProcesses) 'active export client recognized'
    Assert-True (-not (Test-ExportClientActive -Distro 'Other-Distro' -GetProcesses $activeExportProcesses)) 'unrelated export client ignored'

    $state = [ordered]@{}
    1..6 | ForEach-Object { $state["Task $_"] = ($_ -ne 6) }
    $getTasks = {
        param($pattern)
        @($state.Keys | ForEach-Object {
            [pscustomobject]@{TaskName=$_;State=$(if($state[$_]){'Ready'}else{'Disabled'})}
        })
    }
    $disable = { param($name) $state[$name] = $false }
    $enable = { param($name) $state[$name] = $true }
    $taskState = @(Get-BackupTaskState -GetTasks $getTasks)
    Assert-True ($taskState.Count -eq 6) 'captured six task states'
    Suspend-BackupTasks -TaskState $taskState -GetTasks $getTasks -DisableTask $disable -EnableTask $enable
    Assert-True ((@($state.Values | Where-Object { $_ }).Count) -eq 0) 'all enabled tasks suspended'
    Restore-BackupTaskState -TaskState $taskState -EnableTask $enable -DisableTask $disable
    Assert-True ($state['Task 1'] -and -not $state['Task 6']) 'original task state restored exactly'

    $rollbackState = [ordered]@{}
    1..6 | ForEach-Object { $rollbackState["Task $_"] = $true }
    $rollbackGet = { param($pattern) @($rollbackState.Keys | ForEach-Object {[pscustomobject]@{TaskName=$_;State=$(if($rollbackState[$_]){'Ready'}else{'Disabled'})}}) }
    $counter = [pscustomobject]@{Calls=0}
    $failingDisable = { param($name) $counter.Calls++; if($counter.Calls -eq 2){throw 'injected disable failure'}; $rollbackState[$name]=$false }
    $rollbackEnable = { param($name) $rollbackState[$name]=$true }
    $rollbackTaskState = @(Get-BackupTaskState -GetTasks $rollbackGet)
    Expect-Throw { Suspend-BackupTasks -TaskState $rollbackTaskState -GetTasks $rollbackGet -DisableTask $failingDisable -EnableTask $rollbackEnable } 'injected disable failure'
    Assert-True ((@($rollbackState.Values | Where-Object { -not $_ }).Count) -eq 0) 'partial suspension rolled back'

    $restoreCounter = [pscustomobject]@{Calls=0}
    $restoreState = @([pscustomobject]@{Name='A';WasEnabled=$true},[pscustomobject]@{Name='B';WasEnabled=$true},[pscustomobject]@{Name='C';WasEnabled=$true})
    $partlyFailingEnable = { param($name) $restoreCounter.Calls++; if($name -eq 'A'){throw 'injected restore failure'} }
    Expect-Throw { Restore-BackupTaskState -TaskState $restoreState -EnableTask $partlyFailingEnable } 'Could not restore task state'
    Assert-True ($restoreCounter.Calls -eq 3) 'task restoration attempts every task after a failure'

    $journalPath = Join-Path $root 'state\active-run.json'
    $current = Get-Process -Id $PID
    $journal = [ordered]@{ProcessId=$PID;ProcessStartedAt=$current.StartTime.ToString('o');Stage='test'}
    Write-AtomicJson -Value $journal -Path $journalPath
    $readJournal = Read-RunJournal -Path $journalPath
    Assert-True (Test-JournalProcessActive $readJournal) 'active journal process recognized'
    $readJournal.ProcessId = 2147483647
    Assert-True (-not (Test-JournalProcessActive $readJournal)) 'abandoned journal recognized'

    $archive = Join-Path $root '20260824T000000Z_Debian-Recovered.tar.gz'
    [IO.File]::WriteAllText($archive, 'fixture archive data')
    $hash = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifestPath = $archive + '.manifest.json'
    $manifest = [ordered]@{
        SchemaVersion=1;Distro='Debian-Recovered';CreatedAt=(Get-Date).ToUniversalTime().ToString('o')
        Archive=[IO.Path]::GetFileName($archive);ArchiveBytes=(Get-Item $archive).Length;Sha256=$hash;Format='tar.gz'
        Validation=[ordered]@{Result='passed';Files=123;PiSessions=4};WslVersion='WSL version: fixture'
    }
    Write-AtomicJson -Value $manifest -Path $manifestPath
    $manifestResult = Test-BackupManifest -ManifestPath $manifestPath
    Assert-True ($manifestResult.Result -eq 'passed' -and $manifestResult.HashRead) 'valid manifest and hash accepted'

    $malformed = [ordered]@{}
    foreach($key in $manifest.Keys) { $malformed[$key] = $manifest[$key] }
    $malformed.Validation = @($manifest.Validation, $manifest.Validation)
    Write-AtomicJson -Value $malformed -Path $manifestPath
    Expect-Throw { Test-BackupManifest -ManifestPath $manifestPath -SkipHash } 'must be an object'
    $malformed.Validation = $manifest.Validation
    $malformed.Archive = '..\outside.tar.gz'
    Write-AtomicJson -Value $malformed -Path $manifestPath
    Expect-Throw { Test-BackupManifest -ManifestPath $manifestPath -SkipHash } 'leaf filename'
    $malformed.Archive = $manifest.Archive
    $malformed.WslVersion = "bad`0version"
    Write-AtomicJson -Value $malformed -Path $manifestPath
    Expect-Throw { Test-BackupManifest -ManifestPath $manifestPath -SkipHash } 'NUL'
    Write-AtomicJson -Value $manifest -Path $manifestPath

    [IO.File]::WriteAllText((Join-Path $root 'one.tar.gz.partial'), '')
    [IO.File]::WriteAllText((Join-Path $root 'two.tar.gz.partial.failed'), '')
    [IO.File]::WriteAllText((Join-Path $root 'three.tar.gz.failed'), '')
    [IO.File]::WriteAllText((Join-Path $root 'ignored.txt'), '')
    Assert-True ((@(Get-BackupArtifacts -Directory $root).Count) -eq 3) 'failed artifact discovery'

    $retentionRoot = Join-Path $root 'retention'
    New-Item -ItemType Directory -Path $retentionRoot | Out-Null
    foreach($name in '20260101T000000Z_Debian-Recovered.tar.gz','20260201T000000Z_Debian-Recovered.tar.gz','20260301T000000Z_Debian-Recovered.tar.gz') {
        [IO.File]::WriteAllText((Join-Path $retentionRoot $name), '')
    }
    $old = @(Get-OldBackupGenerations -Directory $retentionRoot -Distro 'Debian-Recovered' -Keep 2)
    Assert-True ($old.Count -eq 1 -and $old[0].Name -like '20260101*') 'two-generation retention selection'

    Write-Output "WslSystemBackup tests passed: $tests assertions"
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
