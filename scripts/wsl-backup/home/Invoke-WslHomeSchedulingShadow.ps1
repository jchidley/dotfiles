#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $FixturePath,
    [switch] $ReadOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1')

function Get-ShadowProperty {
    param([Parameter(Mandatory = $true)] $Object, [Parameter(Mandatory = $true)][string] $Name)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { throw "Shadow fixture is missing field: $Name" }
    $property.Value
}

function Assert-ShadowInteger {
    param([Parameter(Mandatory = $true)] $Value, [Parameter(Mandatory = $true)][string] $Name,
        [long] $Minimum = 0)
    if ($Value -isnot [byte] -and $Value -isnot [sbyte] -and $Value -isnot [int16] -and
        $Value -isnot [uint16] -and $Value -isnot [int32] -and $Value -isnot [uint32] -and
        $Value -isnot [int64] -and $Value -isnot [uint64]) {
        throw "Shadow fixture field $Name must be an integer"
    }
    $number = [long]$Value
    if ($number -lt $Minimum) { throw "Shadow fixture field $Name must be at least $Minimum" }
    $number
}

function Assert-ShadowBoolean {
    param([Parameter(Mandatory = $true)] $Value, [Parameter(Mandatory = $true)][string] $Name)
    if ($Value -isnot [bool]) { throw "Shadow fixture field $Name must be a boolean" }
    [bool]$Value
}

function Get-ShadowArrayProperty {
    param([Parameter(Mandatory = $true)] $Object, [Parameter(Mandatory = $true)][string] $Name)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { throw "Shadow fixture is missing field: $Name" }
    if ($property.Value -isnot [array]) { throw "Shadow fixture field $Name must be an array" }
    ,@($property.Value)
}

function Get-ShadowBackupOutcome {
    param([Parameter(Mandatory = $true)] $Result)
    $exitCode = Assert-ShadowInteger (Get-ShadowProperty $Result 'ExitCode') 'ExitCode'
    $class = [string](Get-ShadowProperty $Result 'ResultClass')
    if ($exitCode -eq 0 -and $class -in @('Changed','NoChange')) {
        return [pscustomobject]@{ Result = $class; Due = $false; Reason = 'Successful backup attempt' }
    }
    if ($exitCode -eq 75 -and $class -eq 'Lock') {
        return [pscustomobject]@{ Result = 'DeferredLock'; Due = $true; Reason = 'Linux lock exit 75' }
    }
    if ($exitCode -ne 0 -and $exitCode -ne 75 -and $class -eq 'Failed') {
        return [pscustomobject]@{ Result = 'Failed'; Due = $true; Reason = 'Backup returned a nonzero exit code' }
    }
    throw "Unsupported backup result contract: exit $exitCode, class $class"
}

Assert-PowerShell7
if (-not $ReadOnly) { throw 'Shadow coordinator requires explicit -ReadOnly' }
if (-not (Test-Path -LiteralPath $FixturePath -PathType Leaf)) { throw "Shadow fixture is absent: $FixturePath" }
try { $fixture = Get-Content -LiteralPath $FixturePath -Raw | ConvertFrom-Json -ErrorAction Stop }
catch { throw "Shadow fixture is unreadable or malformed: $FixturePath" }
if ($null -eq $fixture -or $fixture -is [array]) { throw 'Shadow fixture must be a JSON object' }
if ((Assert-ShadowInteger (Get-ShadowProperty $fixture 'SchemaVersion') 'SchemaVersion') -ne 1) {
    throw 'Unsupported shadow fixture schema version'
}
$interval = Assert-ShadowInteger (Get-ShadowProperty $fixture 'PeriodicIntervalMinutes') 'PeriodicIntervalMinutes' 1
$suspendedDays = Assert-ShadowInteger (Get-ShadowProperty $fixture 'SuspendedDays') 'SuspendedDays'
$previousAttemptProperty = Get-ShadowProperty $fixture 'PreviousAttemptAwakeMinute'
$previousAttempt = if ($null -eq $previousAttemptProperty) { $null } else {
    Assert-ShadowInteger $previousAttemptProperty 'PreviousAttemptAwakeMinute'
}
$consecutiveFailures = Assert-ShadowInteger (Get-ShadowProperty $fixture 'ConsecutiveBackupFailures') 'ConsecutiveBackupFailures'
$consecutiveDeferrals = Assert-ShadowInteger (Get-ShadowProperty $fixture 'ConsecutiveBackupDeferrals') 'ConsecutiveBackupDeferrals'
if ($consecutiveFailures -gt 0 -and $consecutiveDeferrals -gt 0) {
    throw 'Shadow fixture cannot have consecutive failures and deferrals simultaneously'
}
if ($null -eq $previousAttempt -and ($consecutiveFailures -gt 0 -or $consecutiveDeferrals -gt 0)) {
    throw 'Shadow fixture health counters require a previous backup attempt'
}
$failureThreshold = Assert-ShadowInteger (Get-ShadowProperty $fixture 'FailureWarningThreshold') 'FailureWarningThreshold' 2
$deferralThreshold = Assert-ShadowInteger (Get-ShadowProperty $fixture 'DeferralWarningThreshold') 'DeferralWarningThreshold' 2
$alreadyRunning = Assert-ShadowBoolean (Get-ShadowProperty $fixture 'CoordinatorAlreadyRunning') 'CoordinatorAlreadyRunning'
$opportunities = Get-ShadowArrayProperty $fixture 'Opportunities'
$maintenance = Get-ShadowArrayProperty $fixture 'Maintenance'

$normalizedOpportunities = [System.Collections.Generic.List[object]]::new()
$lastEventAwakeMinute = $null
foreach ($opportunity in $opportunities) {
    $kind = [string](Get-ShadowProperty $opportunity 'Kind')
    $at = Assert-ShadowInteger (Get-ShadowProperty $opportunity 'AwakeMinute') 'AwakeMinute'
    if ($kind -notin @('Resume','Periodic')) { throw "Unsupported shadow opportunity kind: $kind" }
    if ($null -ne $lastEventAwakeMinute -and $at -lt $lastEventAwakeMinute) {
        throw 'Shadow opportunities must use nondecreasing awake minutes'
    }
    if ($null -ne $previousAttempt -and $at -lt $previousAttempt) {
        throw 'Shadow opportunity precedes the previous backup attempt'
    }
    $lastEventAwakeMinute = $at
    $normalizedOpportunities.Add([pscustomobject]@{
        Kind = $kind
        AwakeMinute = $at
        BackupOutcome = Get-ShadowBackupOutcome -Result (Get-ShadowProperty $opportunity 'BackupResult')
    })
}
$normalizedMaintenance = [System.Collections.Generic.List[object]]::new()
foreach ($operation in $maintenance) {
    $name = [string](Get-ShadowProperty $operation 'Name')
    if ([string]::IsNullOrWhiteSpace($name)) { throw 'Shadow maintenance operation name must not be empty' }
    $normalizedMaintenance.Add([pscustomobject]@{
        Name = $name
        Due = Assert-ShadowBoolean (Get-ShadowProperty $operation 'Due') 'Maintenance.Due'
        Eligible = Assert-ShadowBoolean (Get-ShadowProperty $operation 'Eligible') 'Maintenance.Eligible'
    })
}

$decisions = [System.Collections.Generic.List[object]]::new()
$sequence = 0
$backupVerified = $false
$backupBlockedMaintenance = $false

if ($alreadyRunning) {
    $decisions.Add([pscustomobject][ordered]@{
        Sequence=1; Kind='Coordinator'; Trigger='Overlap'; Action='NoOp'; Result='OverlapRefused';
        Due=$false; Reason='Another coordinator instance is already active'
    })
} else {
    foreach ($opportunity in $normalizedOpportunities) {
        $kind = $opportunity.Kind
        $at = $opportunity.AwakeMinute
        $due = $kind -eq 'Resume' -or $null -eq $previousAttempt -or ($at - $previousAttempt -ge $interval)
        if (-not $due) {
            $sequence++
            $decisions.Add([pscustomobject][ordered]@{
                Sequence=$sequence; Kind='Backup'; Trigger=$kind; Action='NoOp'; Result='NotDue'; Due=$false;
                Reason='Awake interval since previous attempt not reached'
            })
            continue
        }
        $outcome = $opportunity.BackupOutcome
        $sequence++
        $decisions.Add([pscustomobject][ordered]@{
            Sequence=$sequence; Kind='Backup'; Trigger=$kind; Action='Attempt'; Result=$outcome.Result;
            Due=$outcome.Due; Reason=$outcome.Reason
        })
        $previousAttempt = $at
        switch ($outcome.Result) {
            { $_ -in @('Changed','NoChange') } {
                $consecutiveFailures = 0
                $consecutiveDeferrals = 0
                $backupVerified = $true
                $backupBlockedMaintenance = $false
                break
            }
            'Failed' {
                $consecutiveFailures++
                $consecutiveDeferrals = 0
                $backupVerified = $false
                $backupBlockedMaintenance = $true
                break
            }
            'DeferredLock' {
                $consecutiveDeferrals++
                $consecutiveFailures = 0
                $backupVerified = $false
                $backupBlockedMaintenance = $true
                break
            }
        }
    }

    $health = if ($consecutiveFailures -ge $failureThreshold -or $consecutiveDeferrals -ge $deferralThreshold) {
        'AttentionRequired'
    } elseif ($normalizedOpportunities.Count -eq 0) {
        'NoOpportunity'
    } else {
        'Healthy'
    }
    $sequence++
    $decisions.Add([pscustomobject][ordered]@{
        Sequence=$sequence; Kind='Health'; Trigger='AwakeOpportunities'; Action='Record'; Result=$health;
        Due=$false; Reason='Health uses explicit consecutive awake-attempt state; suspension does not advance the awake clock'
    })

    $eligible = if ($backupVerified -and -not $backupBlockedMaintenance) {
        @($normalizedMaintenance | Where-Object { $_.Due -and $_.Eligible })
    } else { @() }
    $selectedOperations = @($eligible | Select-Object -First 1)
    foreach ($selected in $selectedOperations) {
        $sequence++
        $decisions.Add([pscustomobject][ordered]@{
            Sequence=$sequence; Kind='Maintenance'; Trigger='DueLedger'; Action='OfferOne'; Result='Selected';
            Due=$true; Operation=[string](Get-ShadowProperty $selected 'Name');
            Reason='First eligible operation in explicit fixture policy order after successful backup handling'
        })
    }
}

[ordered]@{
    Mode = 'Shadow'
    ReadOnly = $true
    PeriodicIntervalMinutes = $interval
    SuspendedDays = $suspendedDays
    State = [ordered]@{
        PreviousAttemptAwakeMinute = $previousAttempt
        ConsecutiveBackupFailures = $consecutiveFailures
        ConsecutiveBackupDeferrals = $consecutiveDeferrals
    }
    Decisions = @($decisions)
} | ConvertTo-Json -Depth 8
