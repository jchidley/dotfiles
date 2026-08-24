[CmdletBinding()]
param(
    [ValidateSet('Preflight', 'Export', 'Validate', 'Status', 'Recover', 'ValidateManifest', 'Cleanup')]
    [string] $Mode = 'Preflight',
    [string] $Distro = 'Debian-Recovered',
    [string] $StagingDirectory = (Join-Path $env:USERPROFILE 'wsl-backup-staging\distro-exports'),
    [string] $ArchivePath,
    [switch] $ConfirmMaintenanceWindow,
    [switch] $SourceAlreadyStopped,
    [switch] $ConfirmCleanup,
    [switch] $RemoveFailedArtifacts,
    [switch] $RemoveValidationDirectories,
    [int64] $MinimumFreeBytes = 45GB
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'WslSystemBackup.Common.ps1')
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$validator = '/usr/local/sbin/validate-wsl-system-restore'
$temporaryValidator = '/tmp/validate-wsl-system-restore-current'
$resticTaskPattern = 'WSL Home Restic - *'
$stateDirectory = Join-Path $env:LOCALAPPDATA 'WSLSystemBackup'
$journalPath = Join-Path $stateDirectory 'active-run.json'
$logDirectory = Join-Path $stateDirectory 'logs'

function Invoke-WslChecked {
    param([Parameter(Mandatory = $true)][string[]] $Arguments)
    & $wsl @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "wsl.exe failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
    }
}

function Get-DistroNames {
    @(& $wsl --list --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ }
}

function Test-DistroRunning {
    param([string] $Name)
    $running = @(& $wsl --list --running --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() }
    return $running -contains $Name
}

function Assert-Preflight {
    $distros = @(Get-DistroNames)
    if ($distros -notcontains $Distro) {
        throw "Expected WSL distro is not registered: $Distro"
    }
    $root = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($StagingDirectory))
    $free = ([IO.DriveInfo]::new($root)).AvailableFreeSpace
    if ($free -lt $MinimumFreeBytes) {
        throw "Insufficient free space on ${root}: $free bytes; require $MinimumFreeBytes"
    }
    if ($SourceAlreadyStopped) {
        if (Test-DistroRunning $Distro) {
            throw "$Distro is running despite -SourceAlreadyStopped"
        }
        $validatorState = 'deferred; previously installed and source remains stopped'
    }
    else {
        Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'test', '-x', $validator)
        $validatorState = $validator
    }
    [pscustomobject]@{
        Distro = $Distro
        DistroRunning = (Test-DistroRunning $Distro)
        StagingDirectory = $StagingDirectory
        AvailableBytes = $free
        RequiredBytes = $MinimumFreeBytes
        Validator = $validatorState
    }
}

function Test-ImportedArchive {
    param([Parameter(Mandatory = $true)][string] $Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $name = 'Debian-backup-validation-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
    $directory = Join-Path $env:LOCALAPPDATA "WSLSystemBackupValidation\$name"
    $registered = $false
    try {
        New-Item -ItemType Directory -Path (Split-Path -Parent $directory) -Force | Out-Null
        Invoke-WslChecked @('--import', $name, $directory, $resolved, '--version', '2') | Out-Null
        $registered = $true
        Invoke-WslChecked @('--manage', $name, '--set-default-user', 'jack') | Out-Null
        $hostValidator = Convert-ToWslPath (Join-Path $PSScriptRoot 'validate-wsl-system-restore')
        Invoke-WslChecked @('-d', $name, '-u', 'root', '--', 'install', '-o', 'root', '-g', 'root', '-m', '755', $hostValidator, $temporaryValidator) | Out-Null
        $validatorOutput = @(Invoke-WslChecked @('-d', $name, '-u', 'root', '--', $temporaryValidator) |
            ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
        $summary = @($validatorOutput | Where-Object { $_ -match '^restore_validation=passed files=(\d+) sessions=(\d+)$' })
        if ($summary.Count -ne 1) {
            throw "Restore validator did not return one parseable summary"
        }
        [void]($summary[0] -match '^restore_validation=passed files=(\d+) sessions=(\d+)$')
        return [pscustomobject]@{
            Result = 'passed'
            ValidatedAt = (Get-Date).ToUniversalTime().ToString('o')
            DisposableDistro = $name
            Files = [int]$Matches[1]
            PiSessions = [int]$Matches[2]
        }
    }
    finally {
        if ($registered) {
            & $wsl --unregister $name | Out-Null
        }
        if (Test-Path -LiteralPath $directory) {
            Remove-Item -LiteralPath $directory -Recurse -Force
        }
    }
}

function Write-RunLog {
    param([string] $Message)
    if ($script:runLogPath) {
        Add-Content -LiteralPath $script:runLogPath -Encoding UTF8 -Value (
            '{0} {1}' -f (Get-Date).ToString('o'), $Message
        )
    }
}

function Set-RunStage {
    param([string] $Stage)
    $script:journalRecord.Stage = $Stage
    $script:journalRecord.UpdatedAt = (Get-Date).ToUniversalTime().ToString('o')
    Write-AtomicJson -Value $script:journalRecord -Path $journalPath
    Write-RunLog "stage=$Stage"
}

function Show-SystemBackupStatus {
    $journal = Read-RunJournal -Path $journalPath
    $journalState = 'absent'
    if ($journal) {
        $journalState = $(if (Test-JournalProcessActive $journal) { 'active' } else { 'abandoned' })
    }
    Write-Output "journal=$journalState path=$journalPath"
    Write-Output "export_client_active=$(Test-ExportClientActive -Distro $Distro)"
    if ($journal) {
        Write-Output "run_id=$($journal.RunId) stage=$($journal.Stage) process_id=$($journal.ProcessId)"
    }
    Write-Output 'tasks:'
    Get-ScheduledTask -TaskName $resticTaskPattern -ErrorAction SilentlyContinue |
        Sort-Object TaskName | Select-Object TaskName, State | Format-Table -AutoSize
    $artifacts = @(Get-BackupArtifacts -Directory $StagingDirectory)
    Write-Output "failed_artifacts=$($artifacts.Count)"
    $artifacts | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    $validationRoot = Join-Path $env:LOCALAPPDATA 'WSLSystemBackupValidation'
    $validationDirectories = @(Get-ChildItem -LiteralPath $validationRoot -Directory -Force -ErrorAction SilentlyContinue)
    Write-Output "validation_directories=$($validationDirectories.Count)"
    $manifests = @(Get-ChildItem -LiteralPath $StagingDirectory -Filter '*.tar.gz.manifest.json' -File -ErrorAction SilentlyContinue)
    foreach ($item in $manifests) {
        try {
            $result = Test-BackupManifest -ManifestPath $item.FullName -SkipHash
            Write-Output "manifest=valid archive=$([IO.Path]::GetFileName($result.Archive))"
        }
        catch {
            Write-Output "manifest=invalid path=$($item.FullName) reason=$($_.Exception.Message)"
        }
    }
}

if ($Mode -eq 'Preflight') {
    Assert-Preflight | Format-List
    exit 0
}
if ($Mode -eq 'Status') {
    Show-SystemBackupStatus
    exit 0
}

$mutexName = 'Local\WSLSystemBackup-' + ($Distro -replace '[^A-Za-z0-9_.-]', '_')
$mutex = [Threading.Mutex]::new($false, $mutexName)
if (-not $mutex.WaitOne(0)) {
    $mutex.Dispose()
    throw "Another whole-system backup operation owns $mutexName"
}

$taskState = @()
$journalCreated = $false
$tasksSuspended = $false
$script:journalRecord = $null
$script:runLogPath = $null
try {
    if ($Mode -eq 'Recover') {
        $journal = Read-RunJournal -Path $journalPath
        if (-not $journal) { Write-Output 'No run journal requires recovery.'; return }
        if ($journal.SchemaVersion -ne 1 -or -not $journal.Tasks) { throw 'Run journal schema or task state is invalid' }
        if (Test-JournalProcessActive $journal) { throw "Run is still active: $($journal.RunId)" }
        if (Test-ExportClientActive -Distro $journal.Distro) { throw "A WSL export client is still active for $($journal.Distro)" }
        Restore-BackupTaskState -TaskState @($journal.Tasks)
        Remove-Item -LiteralPath $journalPath -Force
        Write-Output "Recovered task state from abandoned run: $($journal.RunId)"
        return
    }

    if ($Mode -eq 'ValidateManifest') {
        if (-not $ArchivePath) { throw '-ArchivePath must name a manifest in ValidateManifest mode' }
        Test-BackupManifest -ManifestPath $ArchivePath | Format-List
        return
    }

    if ($Mode -eq 'Cleanup') {
        $journal = Read-RunJournal -Path $journalPath
        if ($journal) { throw 'A run journal exists; use Status and Recover before cleanup' }
        if (Test-ExportClientActive -Distro $Distro) { throw "A WSL export client is still active for $Distro" }
        if (-not $ConfirmCleanup) { throw 'Cleanup requires -ConfirmCleanup' }
        if ($RemoveFailedArtifacts) {
            foreach ($artifact in @(Get-BackupArtifacts -Directory $StagingDirectory)) {
                Remove-Item -LiteralPath $artifact.FullName -Force
                if ($artifact.Name -match '\.tar\.gz\.failed$') {
                    $orphanManifest = $artifact.FullName.Substring(0, $artifact.FullName.Length - '.failed'.Length) + '.manifest.json'
                    Remove-Item -LiteralPath $orphanManifest -Force -ErrorAction SilentlyContinue
                }
                Write-Output "Removed failed artifact: $($artifact.FullName)"
            }
        }
        if ($RemoveValidationDirectories) {
            $root = Join-Path $env:LOCALAPPDATA 'WSLSystemBackupValidation'
            $registeredPaths = @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue |
                ForEach-Object { (Get-ItemProperty $_.PSPath).BasePath } | Where-Object { $_ } |
                ForEach-Object { [IO.Path]::GetFullPath($_.Replace('/', '\')).TrimEnd('\') })
            foreach ($directory in @(Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue)) {
                $normalizedDirectory = [IO.Path]::GetFullPath($directory.FullName).TrimEnd('\')
                if ($registeredPaths -contains $normalizedDirectory) {
                    throw "Refusing to remove a registered validation directory: $($directory.FullName)"
                }
                Remove-Item -LiteralPath $directory.FullName -Recurse -Force
                Write-Output "Removed validation directory: $($directory.FullName)"
            }
        }
        Show-SystemBackupStatus
        return
    }

    if ($Mode -eq 'Validate') {
        if (-not $ArchivePath) { throw '-ArchivePath is required in Validate mode' }
        Test-ImportedArchive -Path $ArchivePath | Format-List
        return
    }

    if (-not $ConfirmMaintenanceWindow) {
        throw 'Export mode stops Debian-Recovered. Re-run with -ConfirmMaintenanceWindow during an approved maintenance window.'
    }

    $existingJournal = Read-RunJournal -Path $journalPath
    if ($existingJournal) {
        $state = $(if (Test-JournalProcessActive $existingJournal) { 'active' } else { 'abandoned' })
        throw "An $state run journal exists; use Status or Recover: $journalPath"
    }

    if (Test-ExportClientActive -Distro $Distro) { throw "A WSL export client is already active for $Distro" }
    Assert-Preflight | Out-Null
    New-Item -ItemType Directory -Path $StagingDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $taskState = @(Get-BackupTaskState -Pattern $resticTaskPattern)
    $process = Get-Process -Id $PID
    $runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $script:runLogPath = Join-Path $logDirectory "$runId.log"
    $script:journalRecord = [ordered]@{
        SchemaVersion = 1
        RunId = $runId
        Distro = $Distro
        ProcessId = $PID
        ProcessStartedAt = $process.StartTime.ToString('o')
        StartedAt = (Get-Date).ToUniversalTime().ToString('o')
        UpdatedAt = (Get-Date).ToUniversalTime().ToString('o')
        Stage = 'journal-created'
        Tasks = $taskState
        Partial = $null
        Final = $null
        Manifest = $null
        Log = $script:runLogPath
    }
    Write-AtomicJson -Value $script:journalRecord -Path $journalPath
    $journalCreated = $true
    Write-RunLog "run_id=$runId distro=$Distro"

    $tasksSuspended = $true
    Suspend-BackupTasks -TaskState $taskState -Pattern $resticTaskPattern
    Set-RunStage 'tasks-suspended'
    Write-Output "Temporarily disabled Restic tasks: $((@($taskState | Where-Object WasEnabled).Name) -join ', ')"

    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $baseName = "${timestamp}_${Distro}"
    $partial = Join-Path $StagingDirectory "$baseName.tar.gz.partial"
    $final = Join-Path $StagingDirectory "$baseName.tar.gz"
    $manifest = "$final.manifest.json"
    if ((Test-Path -LiteralPath $partial) -or (Test-Path -LiteralPath $final)) {
        throw "Refusing to replace an existing generation: $baseName"
    }
    $script:journalRecord.Partial = $partial
    $script:journalRecord.Final = $final
    $script:journalRecord.Manifest = $manifest
    Set-RunStage 'paths-selected'

    $wasRunning = Test-DistroRunning $Distro
    if ($SourceAlreadyStopped -and $wasRunning) {
        throw "$Distro started after preflight; refusing the stopped-source export"
    }
    $exportCompleted = $false
    $promoted = $false
    try {
        if ($wasRunning) {
            Set-RunStage 'synchronizing-source'
            Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'sync')
            Invoke-WslChecked @('--terminate', $Distro)
        }
        try {
            Set-RunStage 'exporting'
            Invoke-WslChecked @('--export', $Distro, $partial, '--format', 'tar.gz')
            $exportCompleted = $true
        }
        finally {
            if ($wasRunning) {
                Invoke-WslChecked @('-d', $Distro, '-u', 'root', '--', 'true')
            }
        }

        Set-RunStage 'hashing'
        $hash = (Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-RunStage 'validating-import'
        $validation = Test-ImportedArchive -Path $partial
        Move-Item -LiteralPath $partial -Destination $final
        $promoted = $true
        $archive = Get-Item -LiteralPath $final
        $record = [ordered]@{
            SchemaVersion = 1
            Distro = $Distro
            CreatedAt = (Get-Date).ToUniversalTime().ToString('o')
            Archive = $archive.Name
            ArchiveBytes = $archive.Length
            Sha256 = $hash
            Format = 'tar.gz'
            Validation = $validation
            WslVersion = (((& $wsl --version | Out-String) -replace "`0", '').Trim())
        }
        Set-RunStage 'writing-manifest'
        Write-AtomicJson -Value $record -Path $manifest -Depth 5
        $manifestCheck = Test-BackupManifest -ManifestPath $manifest -SkipHash
        if ($manifestCheck.Sha256 -ne $hash) { throw 'Generated manifest hash does not match export hash' }

        Set-RunStage 'applying-retention'
        foreach ($old in @(Get-OldBackupGenerations -Directory $StagingDirectory -Distro $Distro -Keep 2)) {
            Remove-Item -LiteralPath $old.FullName -Force
            Remove-Item -LiteralPath ($old.FullName + '.manifest.json') -Force -ErrorAction SilentlyContinue
        }
        Set-RunStage 'completed'
        Write-Output "Validated system generation: $final"
        Write-Output "SHA-256: $hash"
    }
    catch {
        Write-RunLog "error=$($_.Exception.Message -replace '[\r\n]+',' ')"
        if ($exportCompleted -and (Test-Path -LiteralPath $partial)) {
            Move-Item -LiteralPath $partial -Destination ($partial + '.failed') -Force
        }
        if ($promoted -and (Test-Path -LiteralPath $final)) {
            Move-Item -LiteralPath $final -Destination ($final + '.failed') -Force
        }
        Remove-Item -LiteralPath ($manifest + '.partial') -Force -ErrorAction SilentlyContinue
        throw
    }
}
finally {
    try {
        if ($journalCreated -and $tasksSuspended) {
            Restore-BackupTaskState -TaskState $taskState
            Write-RunLog 'tasks=restored'
            Write-Output "Restored Restic tasks: $((@($taskState | Where-Object WasEnabled).Name) -join ', ')"
        }
        if ($journalCreated) {
            Remove-Item -LiteralPath $journalPath -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        if ($journalCreated) {
            $script:journalRecord.Stage = 'task-restore-failed'
            $script:journalRecord.UpdatedAt = (Get-Date).ToUniversalTime().ToString('o')
            Write-AtomicJson -Value $script:journalRecord -Path $journalPath
        }
        throw
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}
