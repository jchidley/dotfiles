#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Inventory', 'InstallOrVerifyLinux', 'DisableLegacy', 'Verify', 'RestoreLegacy', 'DeleteAfterObservation')]
    [string] $Action,
    [string] $DistroName = 'Debian-Recovered',
    [string] $MigrationDirectory = (Join-Path $env:LOCALAPPDATA 'WSLHomeRestic\migration'),
    [string] $ObservationCompleteRecord,
    [string] $FixtureRoot,
    [ValidateSet('', 'AfterJournal', 'AfterFirstDisable', 'AfterAllDisabled', 'AfterLinuxEnable', 'AfterVerification')]
    [string] $FixtureFailAfter = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ExpectedNames = @(
    'WSL Home Restic - Backup',
    'WSL Home Restic - Monitor',
    'WSL Home Restic - Retention',
    'WSL Home Restic - Prune',
    'WSL Home Restic - Check',
    'WSL Home Restic - Read Data Check'
)
$InventoryPath = Join-Path $MigrationDirectory 'legacy-task-inventory.json'
$JournalPath = Join-Path $MigrationDirectory 'migration-state.json'
$SourceDirectory = $PSScriptRoot

function Get-TextSha256([string] $Text) {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Write-AtomicText([string] $Path, [string] $Text) {
    $directory = Split-Path -Parent $Path
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $temporary = Join-Path $directory ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($Path)), [guid]::NewGuid().ToString('N'))
    try {
        $options = [IO.FileOptions]::WriteThrough
        $stream = [IO.FileStream]::new($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None, 4096, $options)
        try {
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        } finally { $stream.Dispose() }
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    } finally { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
}

function Write-JsonAtomic([string] $Path, [object] $Value) {
    Write-AtomicText $Path (($Value | ConvertTo-Json -Depth 30) + "`n")
}

function Read-JsonStrict([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required migration file is absent: $Path" }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 30 -NoEnumerate
}

function Get-FixtureTasksPath { Join-Path $FixtureRoot 'tasks.json' }
function Get-LinuxFixturePath { Join-Path $FixtureRoot 'linux.json' }

function Get-CurrentTaskRecords {
    if ($FixtureRoot) {
        $records = @((Read-JsonStrict (Get-FixtureTasksPath)))
        return @($records | ForEach-Object {
            [pscustomobject]@{ Name = [string]$_.Name; Path = [string]$_.Path; Enabled = [bool]$_.Enabled; Xml = [string]$_.Xml }
        })
    }

    $matching = @(Get-ScheduledTask | Where-Object TaskName -Like 'WSL Home Restic - *')
    return @($matching | ForEach-Object {
        $task = $_
        $xmlText = Export-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
        $enabled = $task.State -ne 'Disabled'
        [pscustomobject]@{ Name = $task.TaskName; Path = $task.TaskPath; Enabled = $enabled; Xml = $xmlText }
    })
}

function Set-FixtureTasks([object[]] $Tasks) { Write-JsonAtomic (Get-FixtureTasksPath) @($Tasks) }

function Assert-ExpectedTaskSet([object[]] $Tasks) {
    if ($Tasks.Count -ne $ExpectedNames.Count) { throw "Expected exactly six matching legacy tasks; found $($Tasks.Count)" }
    foreach ($name in $ExpectedNames) {
        $taskMatches = @($Tasks | Where-Object { $_.Name -ceq $name -and $_.Path -ceq '\' })
        if ($taskMatches.Count -ne 1) { throw "Missing, duplicate, renamed, or non-root legacy task: $name" }
    }
    $unexpected = @($Tasks | Where-Object { $_.Name -cnotin $ExpectedNames -or $_.Path -cne '\' })
    if ($unexpected.Count) { throw "Unexpected matching legacy task: $($unexpected[0].Path)$($unexpected[0].Name)" }
}

function New-InventoryRecord([object] $Task) {
    [xml]$xml = $Task.Xml
    [pscustomobject]@{
        Name = $Task.Name
        Path = $Task.Path
        Enabled = [bool]$Task.Enabled
        Xml = $Task.Xml
        XmlSha256 = Get-TextSha256 $Task.Xml
        Triggers = [string]$xml.Task.Triggers.OuterXml
        Actions = [string]$xml.Task.Actions.OuterXml
        Principal = [string]$xml.Task.Principals.OuterXml
        Settings = [string]$xml.Task.Settings.OuterXml
    }
}

function Read-ValidatedInventory {
    $inventory = Read-JsonStrict $InventoryPath
    if ($inventory.SchemaVersion -ne 1 -or $inventory.ExpectedTaskCount -ne 6) { throw 'Unsupported or malformed migration inventory' }
    $tasks = @($inventory.Tasks)
    Assert-ExpectedTaskSet $tasks
    foreach ($task in $tasks) {
        if ((Get-TextSha256 ([string]$task.Xml)) -cne [string]$task.XmlSha256) { throw "Inventory XML hash mismatch: $($task.Name)" }
        [xml]$null = [string]$task.Xml
        foreach ($field in 'Triggers', 'Actions', 'Principal', 'Settings') {
            if ([string]::IsNullOrWhiteSpace([string]$task.$field)) { throw "Inventory lacks $field for $($task.Name)" }
        }
    }
    $payload = ($tasks | ConvertTo-Json -Depth 20 -Compress)
    if ((Get-TextSha256 $payload) -cne [string]$inventory.TaskSetSha256) { throw 'Inventory task-set hash mismatch' }
    return $inventory
}

function Assert-CurrentMatchesInventory([object] $Inventory) {
    $current = @(Get-CurrentTaskRecords)
    Assert-ExpectedTaskSet $current
    foreach ($captured in @($Inventory.Tasks)) {
        $actual = @($current | Where-Object { $_.Name -ceq $captured.Name -and $_.Path -ceq $captured.Path })[0]
        if ((Get-TextSha256 $actual.Xml) -cne $captured.XmlSha256 -or $actual.Enabled -ne $captured.Enabled) {
            throw "Legacy task drift detected: $($captured.Name)"
        }
    }
}

function Write-Journal([string] $State, [object] $Inventory) {
    Write-JsonAtomic $JournalPath ([ordered]@{
        SchemaVersion = 1
        State = $State
        InventoryTaskSetSha256 = $Inventory.TaskSetSha256
        UpdatedUtc = [DateTime]::UtcNow.ToString('o')
    })
}

function Read-JournalOptional {
    if (-not (Test-Path -LiteralPath $JournalPath)) { return $null }
    $journal = Read-JsonStrict $JournalPath
    if ($journal.SchemaVersion -ne 1) { throw 'Unsupported migration journal' }
    return $journal
}

function Invoke-Linux([ValidateSet('install-or-verify', 'verify-disabled', 'enable', 'disable', 'status')][string] $LinuxAction) {
    if ($FixtureRoot) {
        $state = if (Test-Path -LiteralPath (Get-LinuxFixturePath)) { Read-JsonStrict (Get-LinuxFixturePath) } else { [pscustomobject]@{ Installed = $false; Enabled = $false; ManualVerified = $false } }
        switch ($LinuxAction) {
            'install-or-verify' { $state.Installed = $true; $state.Enabled = $false; $state.ManualVerified = $true }
            'verify-disabled' { if (-not $state.Installed -or $state.Enabled) { throw 'Fixture Linux scheduler is not installed and disabled' } }
            'enable' { if (-not $state.Installed -or -not $state.ManualVerified) { throw 'Fixture Linux scheduler was not verified' }; $state.Enabled = $true }
            'disable' { $state.Enabled = $false }
            'status' { if (-not $state.Installed) { throw 'Fixture Linux scheduler is absent' } }
        }
        Write-JsonAtomic (Get-LinuxFixturePath) $state
        return $state
    }

    $running = @(& wsl.exe --list --running --quiet | ForEach-Object { $_.Trim("`0", "`r", "`n", ' ') } | Where-Object { $_ })
    if ($LASTEXITCODE -ne 0 -or $DistroName -cnotin $running) { throw "Distro must already be running before migration action: $DistroName" }
    $wslAdapter = Join-Path $HOME 'git/agent-skills/skills/windows-env/Invoke-WslExec.ps1'
    if (-not (Test-Path -LiteralPath $wslAdapter -PathType Leaf)) { throw "Required WSL transport adapter is absent: $wslAdapter" }
    $priorWslEnv = $env:WSLENV
    try {
        $env:MIGRATION_WIN_SOURCE = $SourceDirectory
        $env:MIGRATION_LINUX_ACTION = $LinuxAction
        $entries = @('MIGRATION_WIN_SOURCE/p', 'MIGRATION_LINUX_ACTION')
        if ($priorWslEnv) { $entries += $priorWslEnv }
        $env:WSLENV = $entries -join ':'
        $transportScript = @'
set -euo pipefail
exec bash "$MIGRATION_WIN_SOURCE/migrate-linux-scheduler.sh" "$MIGRATION_LINUX_ACTION" "$MIGRATION_WIN_SOURCE"
'@
        & $wslAdapter -Distribution $DistroName -Script $transportScript
        if ($LASTEXITCODE -ne 0) { throw "Linux migration action failed: $LinuxAction" }
    } finally {
        $env:WSLENV = $priorWslEnv
        Remove-Item Env:MIGRATION_WIN_SOURCE, Env:MIGRATION_LINUX_ACTION -ErrorAction SilentlyContinue
    }
}

function Set-AllLegacyDisabled {
    if ($FixtureRoot) {
        $tasks = @(Get-CurrentTaskRecords)
        for ($i = 0; $i -lt $tasks.Count; $i++) {
            $tasks[$i].Enabled = $false
            if ($i -eq 0 -and $FixtureFailAfter -eq 'AfterFirstDisable') { Set-FixtureTasks $tasks; throw 'Injected interruption after first disable' }
        }
        Set-FixtureTasks $tasks
        return
    }
    foreach ($name in $ExpectedNames) { Disable-ScheduledTask -TaskName $name -TaskPath '\' | Out-Null }
}

function Assert-AllLegacyDisabled {
    $current = @(Get-CurrentTaskRecords)
    Assert-ExpectedTaskSet $current
    foreach ($task in $current) { if ($task.Enabled) { throw "Legacy task remained enabled: $($task.Name)" } }
}

function Assert-NoLegacyTasks {
    $current = @(Get-CurrentTaskRecords)
    if ($current.Count -ne 0) { throw "Expected no legacy tasks after deletion; found $($current.Count)" }
}

function Restore-ExactLegacy([object] $Inventory) {
    if ($FixtureRoot) {
        $restored = @($Inventory.Tasks | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Path = $_.Path; Enabled = [bool]$_.Enabled; Xml = $_.Xml } })
        Set-FixtureTasks $restored
    } else {
        foreach ($task in @($Inventory.Tasks)) {
            Register-ScheduledTask -TaskName $task.Name -TaskPath $task.Path -Xml $task.Xml -Force | Out-Null
            if (-not $task.Enabled) { Disable-ScheduledTask -TaskName $task.Name -TaskPath $task.Path | Out-Null }
        }
    }
    Assert-CurrentMatchesInventory $Inventory
}

function Invoke-Rollback([object] $Inventory) {
    Invoke-Linux disable | Out-Null
    Restore-ExactLegacy $Inventory
    Write-Journal 'RolledBack' $Inventory
}

[IO.Directory]::CreateDirectory($MigrationDirectory) | Out-Null
$inventory = $null
if (Test-Path -LiteralPath $InventoryPath) { $inventory = Read-ValidatedInventory }
$journal = Read-JournalOptional
if ($journal -and $journal.State -eq 'CutoverInProgress' -and $Action -notin @('RestoreLegacy', 'DisableLegacy')) {
    if (-not $inventory) { throw 'Interrupted cutover has no valid rollback inventory' }
    Invoke-Rollback $inventory
    throw 'Interrupted cutover was rolled back exactly; review evidence before retrying'
}

switch ($Action) {
    'Inventory' {
        $current = @(Get-CurrentTaskRecords)
        Assert-ExpectedTaskSet $current
        if ($inventory) {
            Assert-CurrentMatchesInventory $inventory
            $inventory
            break
        }
        $records = @($current | Sort-Object Name | ForEach-Object { New-InventoryRecord $_ })
        $taskSetHash = Get-TextSha256 ($records | ConvertTo-Json -Depth 20 -Compress)
        $inventory = [ordered]@{
            SchemaVersion = 1
            CapturedUtc = [DateTime]::UtcNow.ToString('o')
            ComputerName = [Environment]::MachineName
            ExpectedTaskCount = 6
            Tasks = $records
            TaskSetSha256 = $taskSetHash
        }
        Write-JsonAtomic $InventoryPath $inventory
        $inventory = Read-ValidatedInventory
        Assert-CurrentMatchesInventory $inventory
        Write-Journal 'Inventoried' $inventory
        $inventory
    }
    'InstallOrVerifyLinux' {
        if (-not $inventory) { throw 'Validated inventory is required before Linux installation' }
        Assert-CurrentMatchesInventory $inventory
        Invoke-Linux install-or-verify | Out-Null
        Invoke-Linux verify-disabled | Out-Null
        Write-Journal 'LinuxVerified' $inventory
        [pscustomobject]@{ State = 'LinuxVerified'; TimerEnabled = $false; InventoryTaskSetSha256 = $inventory.TaskSetSha256 }
    }
    'DisableLegacy' {
        if (-not $inventory) { throw 'Validated inventory is required before cutover' }
        if ($journal -and $journal.State -eq 'CutoverComplete') { Assert-AllLegacyDisabled; Invoke-Linux status | Out-Null; [pscustomobject]@{ State = 'CutoverComplete' }; break }
        if (-not $journal -or $journal.State -notin @('LinuxVerified', 'RolledBack', 'CutoverInProgress')) { throw 'Linux preflight has not completed' }
        if ($journal.State -eq 'CutoverInProgress') { Invoke-Rollback $inventory; throw 'Interrupted cutover was rolled back exactly; rerun preflight before retrying' }
        Assert-CurrentMatchesInventory $inventory
        Invoke-Linux verify-disabled | Out-Null
        Write-Journal 'CutoverInProgress' $inventory
        try {
            if ($FixtureFailAfter -eq 'AfterJournal') { throw 'Injected interruption after journal' }
            Set-AllLegacyDisabled
            if ($FixtureFailAfter -eq 'AfterAllDisabled') { throw 'Injected interruption after all disables' }
            Assert-AllLegacyDisabled
            Invoke-Linux enable | Out-Null
            if ($FixtureFailAfter -eq 'AfterLinuxEnable') { throw 'Injected interruption after Linux enable' }
            Assert-AllLegacyDisabled
            Invoke-Linux status | Out-Null
            if ($FixtureFailAfter -eq 'AfterVerification') { throw 'Injected interruption after verification' }
            Write-Journal 'CutoverComplete' $inventory
        } catch {
            $failure = $_
            Invoke-Rollback $inventory
            throw "Cutover failed and exact rollback was verified: $failure"
        }
        [pscustomobject]@{ State = 'CutoverComplete'; WindowsTasksEnabled = 0; LinuxTimerEnabled = $true }
    }
    'Verify' {
        if (-not $inventory -or -not $journal) { throw 'Migration inventory and journal are required' }
        if ($journal.InventoryTaskSetSha256 -cne $inventory.TaskSetSha256) { throw 'Migration journal does not match inventory' }
        switch ($journal.State) {
            'CutoverComplete' { Assert-AllLegacyDisabled; Invoke-Linux status | Out-Null }
            'RolledBack' { Assert-CurrentMatchesInventory $inventory; Invoke-Linux verify-disabled | Out-Null }
            'LinuxVerified' { Assert-CurrentMatchesInventory $inventory; Invoke-Linux verify-disabled | Out-Null }
            'LegacyDeletedAfterObservation' { Assert-NoLegacyTasks; Invoke-Linux status | Out-Null }
            'LegacyDeletedByExplicitAuthorization' { Assert-NoLegacyTasks; Invoke-Linux status | Out-Null }
            default { throw "Migration is not in a verifiable stable state: $($journal.State)" }
        }
        [pscustomobject]@{ State = $journal.State; InventoryTaskSetSha256 = $inventory.TaskSetSha256 }
    }
    'RestoreLegacy' {
        if (-not $inventory) { throw 'Validated inventory is required for rollback' }
        Invoke-Rollback $inventory
        [pscustomobject]@{ State = 'RolledBack'; RestoredTaskCount = 6; LinuxTimerEnabled = $false }
    }
    'DeleteAfterObservation' {
        if (-not $inventory -or -not $journal -or $journal.State -ne 'CutoverComplete') { throw 'Deletion requires a completed cutover' }
        if (-not $ObservationCompleteRecord) { throw 'Deletion requires an explicit observation-complete record' }
        $observation = Read-JsonStrict $ObservationCompleteRecord
        if ($observation.ObservationComplete -ne $true -or $observation.InventoryTaskSetSha256 -cne $inventory.TaskSetSha256) {
            throw 'Observation-complete record is absent, false, or belongs to another inventory'
        }
        Assert-AllLegacyDisabled
        if ($FixtureRoot) { Set-FixtureTasks @() } else { foreach ($name in $ExpectedNames) { Unregister-ScheduledTask -TaskName $name -TaskPath '\' -Confirm:$false } }
        Write-Journal 'LegacyDeletedAfterObservation' $inventory
        [pscustomobject]@{ State = 'LegacyDeletedAfterObservation'; DeletedTaskCount = 6 }
    }
}
