#requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Preflight','Create','Status')][string]$Mode = 'Preflight',
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'combined-backup.json'),
    [switch]$ConfirmMaintenanceWindow
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$PSStyle.OutputRendering = 'PlainText'
. (Join-Path $PSScriptRoot 'WslSystemBackup.Common.ps1')
$config = Read-CombinedBackupConfig $ConfigPath
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$stateRoot = Join-Path $env:LOCALAPPDATA 'Debian4CombinedBackup'
$journalPath = Join-Path $stateRoot 'active-run.json'
$mutexName = 'Local\Debian4CombinedBackup'
$linuxTargetMount = '/mnt/wsl-combined-backup-target'

function Get-DistroNames([switch]$Running) {
    $arguments = @('--list','--quiet')
    if ($Running) { $arguments = @('--list','--running','--quiet') }
    @(& $wsl @arguments) | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ }
}

function Invoke-WslChecked([string[]]$Arguments) {
    $output = @(& $wsl @Arguments)
    if ($LASTEXITCODE -ne 0) { throw "wsl.exe operation failed (exit $LASTEXITCODE)" }
    return @($output | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
}

function Set-JournalStage([Collections.IDictionary]$Journal, [string]$Stage) {
    $Journal.stage = $Stage
    $Journal.updatedAt = (Get-Date).ToUniversalTime().ToString('o')
    Write-AtomicJson $Journal $journalPath
}

function Resolve-LiveTarget {
    $target = Resolve-CombinedBackupTarget $config
    $system = Assert-SafeTargetPath $target.Root $config.systemRelativePath
    $homeRepository = Assert-SafeTargetPath $target.Root $config.homeRepositoryRelativePath
    [pscustomobject]@{ Identity=$target; SystemPath=$system; HomeRepositoryPath=$homeRepository }
}

function Invoke-HomeCopyHelper([string]$Operation, [string]$LinuxRepositoryPath) {
    $helper = Convert-ToWslDrivePath (Join-Path $PSScriptRoot 'copy-combined-home-snapshot')
    Invoke-WslChecked @('-d','Debian4','-u','root','--','bash',$helper,$Operation,
        '/etc/restic/home.conf',$LinuxRepositoryPath,$config.sourceRepositoryId,$config.externalRepositoryId)
}

function Invoke-SystemCaptureHelper([string]$Operation, [string]$LinuxRepositoryPath) {
    $helper = Convert-ToWslDrivePath (Join-Path $PSScriptRoot 'capture-combined-system')
    Invoke-WslChecked @('-d','Debian4','-u','root','--','bash',$helper,
        '/etc/restic/home.conf',$LinuxRepositoryPath,$config.externalRepositoryId,'/',$Operation)
}

function Mount-CombinedBackupTarget {
    param([Parameter(Mandatory)]$Target)
    & $wsl -d Debian4 -u root -- findmnt --mountpoint $linuxTargetMount -n -o SOURCE
    if ($LASTEXITCODE -eq 0) { throw "Temporary target mount is already occupied: $linuxTargetMount" }
    if ($LASTEXITCODE -ne 1) { throw 'Could not establish temporary target mount state' }
    Invoke-WslChecked @('-d','Debian4','-u','root','--','mkdir','-p',$linuxTargetMount) | Out-Null
    $transport = $Target.Identity.Root.Substring(0,2)
    Invoke-WslChecked @('-d','Debian4','-u','root','--','mount','-t','drvfs',$transport,$linuxTargetMount) | Out-Null
    $source = @(Invoke-WslChecked @('-d','Debian4','-u','root','--','findmnt','--mountpoint',$linuxTargetMount,'-n','-o','SOURCE'))
    if ($source.Count -ne 1 -or $source[0] -ne $transport) {
        throw 'Temporary target mount source is unexpected; preserving uncertain mount state'
    }
    $relative = ([string]$config.homeRepositoryRelativePath).Replace('\','/')
    [pscustomobject]@{ MountPoint=$linuxTargetMount; Source=$transport; Repository="$linuxTargetMount/$relative" }
}

function Dismount-CombinedBackupTarget {
    param([Parameter(Mandatory)]$Mount)
    $source = @(Invoke-WslChecked @('-d','Debian4','-u','root','--','findmnt','--mountpoint',$Mount.MountPoint,'-n','-o','SOURCE'))
    if ($source.Count -ne 1 -or $source[0] -ne $Mount.Source) { throw 'Temporary target mount identity changed; refusing to unmount' }
    Invoke-WslChecked @('-d','Debian4','-u','root','--','umount',$Mount.MountPoint) | Out-Null
    Invoke-WslChecked @('-d','Debian4','-u','root','--','rmdir',$Mount.MountPoint) | Out-Null
}

function Assert-CreatePreflight {
    if ((Get-DistroNames) -notcontains 'Debian4') { throw 'Debian4 is not registered' }
    if ((Get-DistroNames -Running) -notcontains 'Debian4') {
        throw 'Debian4 is stopped; preflight will not wake it. Start it normally before an approved run.'
    }
    if (-not (Test-Path -LiteralPath $wsl)) { throw 'Required native wsl.exe is absent' }
    $target = Resolve-LiveTarget
    if ($target.Identity.FreeBytes -lt [int64]$config.minimumFreeBytes) { throw 'Verified target has insufficient free space' }
    if (-not (Test-Path -LiteralPath $target.HomeRepositoryPath -PathType Container)) { throw 'Pinned external Restic repository is absent' }
    $mount = $null
    try {
        $mount = Mount-CombinedBackupTarget $target
        $homeOutput = @(Invoke-HomeCopyHelper preflight $mount.Repository)
        if (@($homeOutput | Where-Object { $_ -match '^repositories_verified source=[0-9a-f]{64} target=[0-9a-f]{64}$' }).Count -ne 1) {
            throw 'Home repository preflight did not return its exact identity result'
        }
        $systemOutput = @(Invoke-SystemCaptureHelper preflight $mount.Repository)
        if (@($systemOutput | Where-Object { $_ -match '^system_repository_verified target=[0-9a-f]{64}$' }).Count -ne 1) {
            throw 'System repository preflight did not return its exact identity result'
        }
    }
    finally { if ($mount) { Dismount-CombinedBackupTarget $mount } }
    [pscustomobject]@{
        Distro='Debian4'; SourceRunning=$true; TargetLabel=$config.targetLabel
        TargetVolume=$target.Identity.VolumeId; FreeBytes=$target.Identity.FreeBytes
        ManifestDestination=$target.SystemPath; ResticRepository=$target.HomeRepositoryPath
        SourceRepositoryId=$config.sourceRepositoryId; ExternalRepositoryId=$config.externalRepositoryId
        ExternalWritesPerformed=$false; TemporaryGuestMount=$true; Encryption='existing Restic repository keys'
    }
}

if ($Mode -eq 'Status') {
    if (Test-Path -LiteralPath $journalPath) {
        Write-Output "incomplete_run=$journalPath"
        Get-Content -LiteralPath $journalPath -Raw
    } else { Write-Output 'incomplete_run=none' }
    Write-Output "debian4_running=$((Get-DistroNames -Running) -contains 'Debian4')"
    exit 0
}
if ($Mode -in @('Preflight','Create')) {
    throw 'Combined capture is disabled pending the reviewed offline tar/gzip replacement. Existing backups are preserved; do not retry the root-freeze implementation.'
}
if ($Mode -eq 'Preflight') { Assert-CreatePreflight | Format-List; exit 0 }
if (-not $ConfirmMaintenanceWindow) { throw 'Create requires -ConfirmMaintenanceWindow because it writes Restic snapshots and briefly freezes Debian4 writes' }
if (Test-Path -LiteralPath $journalPath) { throw "An incomplete run requires inspection before retry: $journalPath" }

$mutex = [Threading.Mutex]::new($false, $mutexName)
if (-not $mutex.WaitOne(0)) { $mutex.Dispose(); throw 'Another Debian4 combined backup operation is active' }
$timerWasActive = $false
$timerSuspended = $false
$journal = $null
$targetMount = $null
try {
    [void](Assert-CreatePreflight)
    $target = Resolve-LiveTarget
    New-Item -ItemType Directory -Path $target.SystemPath -Force | Out-Null
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $partialDirectory = Join-Path $target.SystemPath "$timestamp.partial"
    $finalDirectory = Join-Path $target.SystemPath $timestamp
    if ((Test-Path -LiteralPath $partialDirectory) -or (Test-Path -LiteralPath $finalDirectory)) {
        throw 'Refusing to replace an existing combined-backup generation'
    }
    $journal = [ordered]@{
        schemaVersion=1; runId=$timestamp; distro='Debian4'; processId=$PID
        processStartedAt=(Get-Process -Id $PID).StartTime.ToString('o')
        startedAt=(Get-Date).ToUniversalTime().ToString('o'); updatedAt=(Get-Date).ToUniversalTime().ToString('o')
        stage='prepared'; targetLabel=$config.targetLabel; partialDirectory=$partialDirectory; finalDirectory=$finalDirectory
    }
    Write-AtomicJson $journal $journalPath
    New-Item -ItemType Directory -Path $partialDirectory | Out-Null

    & $wsl -d Debian4 -u root -- systemctl is-active --quiet wsl-home-scheduler.timer
    if ($LASTEXITCODE -eq 0) { $timerWasActive = $true }
    elseif ($LASTEXITCODE -eq 3) { $timerWasActive = $false }
    else { throw 'Could not establish the home scheduler timer state' }
    & $wsl -d Debian4 -u root -- systemctl is-active --quiet wsl-home-scheduler.service
    if ($LASTEXITCODE -eq 0) { throw 'The home scheduler service is active; wait for it to finish before the maintenance window' }
    if ($LASTEXITCODE -ne 3) { throw 'Could not establish the home scheduler service state' }
    Set-JournalStage $journal 'stopping-timer'
    Invoke-WslChecked @('-d','Debian4','-u','root','--','systemctl','stop','wsl-home-scheduler.timer') | Out-Null
    $timerSuspended = $true
    & $wsl -d Debian4 -u root -- systemctl is-active --quiet wsl-home-scheduler.service
    if ($LASTEXITCODE -eq 0) { throw 'The scheduler raced with timer suspension; no combined capture was started' }
    if ($LASTEXITCODE -ne 3) { throw 'Could not verify scheduler quiescence' }

    Set-JournalStage $journal 'creating-local-home-snapshot'
    Invoke-WslChecked @('-d','Debian4','-u','root','--','/usr/local/sbin/backup-wsl-home','backup') | Out-Null
    $target = Resolve-LiveTarget
    $targetMount = Mount-CombinedBackupTarget $target

    Set-JournalStage $journal 'copying-home-snapshot'
    $copyOutput = @(Invoke-HomeCopyHelper copy $targetMount.Repository)
    $copyLine = @($copyOutput | Where-Object { $_ -match '^snapshot_copied source_snapshot=([0-9a-f]{64}) target_snapshot=([0-9a-f]{64})$' })
    if ($copyLine.Count -ne 1) { throw 'Home-copy helper did not return one copied snapshot identity pair' }
    [void]($copyLine[0] -match '^snapshot_copied source_snapshot=([0-9a-f]{64}) target_snapshot=([0-9a-f]{64})$')
    $homeSnapshot = $Matches[1]
    $homeTargetSnapshot = $Matches[2]

    Set-JournalStage $journal 'streaming-system-snapshot'
    $systemOutput = @(Invoke-SystemCaptureHelper capture $targetMount.Repository)
    $systemLine = @($systemOutput | Where-Object { $_ -match '^system_snapshot_created id=([0-9a-f]{64}) filename=system\.tar\.gz$' })
    if ($systemLine.Count -ne 1) { throw 'System-capture helper did not return one snapshot identity' }
    [void]($systemLine[0] -match '^system_snapshot_created id=([0-9a-f]{64}) filename=system\.tar\.gz$')
    $systemSnapshot = $Matches[1]
    Dismount-CombinedBackupTarget $targetMount
    $targetMount = $null

    Set-JournalStage $journal 'writing-completion-record'
    $manifest = [ordered]@{
        schemaVersion=1; completedAt=(Get-Date).ToUniversalTime().ToString('o'); distro='Debian4'
        targetLabel=$config.targetLabel; volumeId=$config.volumeId
        repositoryRelativePath=$config.homeRepositoryRelativePath; repositoryId=$config.externalRepositoryId
        homeSourceSnapshotId=$homeSnapshot; homeTargetSnapshotId=$homeTargetSnapshot; systemSnapshotId=$systemSnapshot; systemSnapshotFilename='system.tar.gz'
        systemExclusions=@('/home/jack','/var/lib/restic/home','/etc/restic/home.password','/dev','/proc','/run','/sys','/mnt')
        consistency='fresh home snapshot copied with Restic locks; system tar streamed while the ext4 root was fsfreeze-frozen'
        encryption='Restic repository keys'; plaintextSystemArtifactCreated=$false; finalDistroState='running'
    }
    Write-AtomicJson $manifest (Join-Path $partialDirectory 'manifest.json')
    $target = Resolve-LiveTarget
    if ($target.SystemPath -ne (Split-Path -Parent $partialDirectory)) { throw 'Verified target path changed before promotion' }
    Complete-CombinedGeneration $partialDirectory $finalDirectory
    Remove-Item -LiteralPath $journalPath -Force
    Write-Output "Combined backup completed: $finalDirectory"
    Write-Output "Home snapshot copied: $homeSnapshot"
    Write-Output "System snapshot stored in Restic: $systemSnapshot"
}
finally {
    $cleanupErrors = [Collections.Generic.List[string]]::new()
    if ($targetMount) {
        try { Dismount-CombinedBackupTarget $targetMount }
        catch { $cleanupErrors.Add("target mount: $($_.Exception.Message)") }
    }
    if ($timerSuspended -and $timerWasActive -and ((Get-DistroNames -Running) -contains 'Debian4')) {
        try { Invoke-WslChecked @('-d','Debian4','-u','root','--','systemctl','start','wsl-home-scheduler.timer') | Out-Null }
        catch {
            $cleanupErrors.Add("scheduler timer: $($_.Exception.Message)")
            if ($journal) { try { Set-JournalStage $journal 'timer-restore-failed' } catch { } }
        }
    }
    $mutex.ReleaseMutex()
    $mutex.Dispose()
    if ($cleanupErrors.Count -gt 0) { throw "Combined backup cleanup requires inspection: $($cleanupErrors -join '; ')" }
}
