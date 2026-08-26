#requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$script:tests = 0
function Assert-True {
    param([bool] $Condition, [string] $Message)
    $script:tests++
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}
function Expect-Throw {
    param([scriptblock] $Action, [string] $Pattern)
    $script:tests++
    try { & $Action; throw 'expected throw' }
    catch {
        if ($_.Exception.Message -eq 'expected throw' -or $_.Exception.Message -notmatch $Pattern) {
            throw "Unexpected error '$($_.Exception.Message)', expected '$Pattern'"
        }
    }
}
function Write-Fixture {
    param($Fixture, [string] $Path)
    $Fixture | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Read-Shadow {
    param($Fixture, [string] $Path, [string] $Source)
    Write-Fixture $Fixture $Path
    & $Source -FixturePath $Path -ReadOnly | ConvertFrom-Json
}
function Copy-Fixture {
    param($Fixture)
    $Fixture | ConvertTo-Json -Depth 8 | ConvertFrom-Json -AsHashtable
}

$source = Join-Path $PSScriptRoot 'Invoke-WslHomeSchedulingShadow.ps1'
$common = Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('wsl-shadow-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $base = [ordered]@{
        SchemaVersion=1
        PeriodicIntervalMinutes=15
        SuspendedDays=3
        PreviousAttemptAwakeMinute=$null
        ConsecutiveBackupFailures=0
        ConsecutiveBackupDeferrals=0
        FailureWarningThreshold=2
        DeferralWarningThreshold=2
        CoordinatorAlreadyRunning=$false
        Opportunities=@(
            [ordered]@{Kind='Resume'; AwakeMinute=0; BackupResult=[ordered]@{ExitCode=0; ResultClass='Changed'}},
            [ordered]@{Kind='Periodic'; AwakeMinute=14; BackupResult=[ordered]@{ExitCode=0; ResultClass='Changed'}},
            [ordered]@{Kind='Periodic'; AwakeMinute=15; BackupResult=[ordered]@{ExitCode=0; ResultClass='NoChange'}},
            [ordered]@{Kind='Periodic'; AwakeMinute=16; BackupResult=[ordered]@{ExitCode=0; ResultClass='Changed'}},
            [ordered]@{Kind='Periodic'; AwakeMinute=29; BackupResult=[ordered]@{ExitCode=0; ResultClass='Changed'}},
            [ordered]@{Kind='Periodic'; AwakeMinute=30; BackupResult=[ordered]@{ExitCode=0; ResultClass='Changed'}}
        )
        Maintenance=@(
            [ordered]@{Name='prune'; Due=$true; Eligible=$true},
            [ordered]@{Name='check'; Due=$true; Eligible=$true}
        )
    }
    $fixturePath = Join-Path $root 'fixture.json'

    $contracts = @{
        SuspensionIndependent = { param($a, $b) ($a.Decisions | ConvertTo-Json -Depth 8) -eq ($b.Decisions | ConvertTo-Json -Depth 8) }
        LockDueNonAlerting = { param($j) $lockResult=@($j.Decisions | Where-Object Result -eq 'DeferredLock'); $lockResult.Count -eq 1 -and $lockResult[0].Due -and (@($j.Decisions | Where-Object Kind -eq 'Health')[0].Result -eq 'Healthy') }
        NoChangeDistinct = { param($j) $attempt=@($j.Decisions | Where-Object { $_.Trigger -eq 'Periodic' -and $_.Action -eq 'Attempt' -and $_.Sequence -eq 3 }); $attempt.Count -eq 1 -and $attempt[0].Result -eq 'NoChange' }
        MaintenanceSerialized = { param($j) $items=@($j.Decisions | Where-Object Kind -eq 'Maintenance'); $items.Count -eq 1 -and $items[0].Operation -eq 'prune' }
        ThresholdBoundary = { param($j) $j.State.ConsecutiveBackupDeferrals -eq 2 -and (@($j.Decisions | Where-Object Kind -eq 'Health')[0].Result -eq 'AttentionRequired') }
        RecoveryResets = { param($j) $j.State.ConsecutiveBackupFailures -eq 0 -and $j.State.ConsecutiveBackupDeferrals -eq 0 -and (@($j.Decisions | Where-Object Kind -eq 'Health')[0].Result -eq 'Healthy') }
    }

    $json = Read-Shadow $base $fixturePath $source
    $decisions = @($json.Decisions)
    Assert-True ($json.Mode -eq 'Shadow' -and $json.ReadOnly) 'shadow read-only output'
    Assert-True ($json.SuspendedDays -eq 3) 'suspended duration remains explicit fixture data'
    Assert-True ($decisions[0].Action -eq 'Attempt' -and $decisions[0].Result -eq 'Changed') 'resume backup is first'
    Assert-True ($decisions[1].Action -eq 'NoOp' -and $decisions[1].Result -eq 'NotDue') 'periodic minute 14 is skipped'
    Assert-True (& $contracts.NoChangeDistinct $json) 'exact boundary records no-change success distinctly'
    Assert-True ($decisions[3].Action -eq 'NoOp' -and $decisions[4].Action -eq 'NoOp' -and $decisions[5].Action -eq 'Attempt') 'interval resets after an attempt at minutes 15, 16, 29, and 30'
    Assert-True ($json.State.PreviousAttemptAwakeMinute -eq 30) 'projected state records the latest attempt awake minute'
    Assert-True ($json.State.ConsecutiveBackupFailures -eq 0 -and $json.State.ConsecutiveBackupDeferrals -eq 0) 'success resets consecutive health counters'
    Assert-True (@($decisions | Where-Object Kind -eq 'Health')[0].Result -eq 'Healthy') 'successful awake opportunities are healthy'
    Assert-True (& $contracts.MaintenanceSerialized $json) 'maintenance is serialized in explicit fixture order'
    Assert-True ((Get-Content -LiteralPath $source -Raw) -cnotmatch 'wsl\.exe|restic|ScheduledTask|msg\.exe|LOCALAPPDATA') 'shadow source has no production adapters'

    $suspendedZero = Copy-Fixture $base
    $suspendedZero.SuspendedDays = 0
    $suspendedJson = Read-Shadow $suspendedZero (Join-Path $root 'suspended-zero.json') $source
    Assert-True (& $contracts.SuspensionIndependent $json $suspendedJson) 'suspended days do not change due decisions or health'

    $lock = Copy-Fixture $base
    $lock.Opportunities = @([ordered]@{Kind='Resume'; AwakeMinute=31; BackupResult=[ordered]@{ExitCode=75; ResultClass='Lock'}})
    $lock.PreviousAttemptAwakeMinute = 30
    $lock.Maintenance = $base.Maintenance
    $lockJson = Read-Shadow $lock (Join-Path $root 'lock.json') $source
    Assert-True (& $contracts.LockDueNonAlerting $lockJson) 'one lock is due but non-alerting'
    Assert-True ($lockJson.State.ConsecutiveBackupDeferrals -eq 1 -and $lockJson.State.ConsecutiveBackupFailures -eq 0) 'lock projects consecutive deferral state'
    Assert-True (@($lockJson.Decisions | Where-Object Kind -eq 'Maintenance').Count -eq 0) 'lock deferral blocks maintenance'

    $secondLock = Copy-Fixture $lock
    $secondLock.PreviousAttemptAwakeMinute = $lockJson.State.PreviousAttemptAwakeMinute
    $secondLock.ConsecutiveBackupDeferrals = $lockJson.State.ConsecutiveBackupDeferrals
    $secondLock.Opportunities = @([ordered]@{Kind='Resume'; AwakeMinute=32; BackupResult=[ordered]@{ExitCode=75; ResultClass='Lock'}})
    $secondLockJson = Read-Shadow $secondLock (Join-Path $root 'second-lock.json') $source
    Assert-True (& $contracts.ThresholdBoundary $secondLockJson) 'deferral threshold crosses on a later invocation'

    $failure = Copy-Fixture $base
    $failure.Opportunities = @([ordered]@{Kind='Resume'; AwakeMinute=31; BackupResult=[ordered]@{ExitCode=2; ResultClass='Failed'}})
    $failure.PreviousAttemptAwakeMinute = 30
    $failure.Maintenance = $base.Maintenance
    $failureJson = Read-Shadow $failure (Join-Path $root 'failure.json') $source
    Assert-True (@($failureJson.Decisions | Where-Object Kind -eq 'Health')[0].Result -eq 'Healthy') 'one ordinary failure is non-alerting'
    Assert-True ($failureJson.State.ConsecutiveBackupFailures -eq 1 -and @($failureJson.Decisions | Where-Object Kind -eq 'Maintenance').Count -eq 0) 'failure remains due and blocks maintenance'

    $secondFailure = Copy-Fixture $failure
    $secondFailure.PreviousAttemptAwakeMinute = $failureJson.State.PreviousAttemptAwakeMinute
    $secondFailure.ConsecutiveBackupFailures = $failureJson.State.ConsecutiveBackupFailures
    $secondFailure.Opportunities = @([ordered]@{Kind='Resume'; AwakeMinute=32; BackupResult=[ordered]@{ExitCode=2; ResultClass='Failed'}})
    $secondFailureJson = Read-Shadow $secondFailure (Join-Path $root 'second-failure.json') $source
    Assert-True (@($secondFailureJson.Decisions | Where-Object Kind -eq 'Health')[0].Result -eq 'AttentionRequired') 'failure threshold crosses on a later invocation'

    $recovery = Copy-Fixture $secondFailure
    $recovery.PreviousAttemptAwakeMinute = $secondFailureJson.State.PreviousAttemptAwakeMinute
    $recovery.ConsecutiveBackupFailures = $secondFailureJson.State.ConsecutiveBackupFailures
    $recovery.Opportunities = @([ordered]@{Kind='Resume'; AwakeMinute=33; BackupResult=[ordered]@{ExitCode=0; ResultClass='NoChange'}})
    $recoveryJson = Read-Shadow $recovery (Join-Path $root 'recovery.json') $source
    Assert-True (& $contracts.RecoveryResets $recoveryJson) 'successful no-change attempt clears prior failure state'

    $overlap = Copy-Fixture $base
    $overlap.CoordinatorAlreadyRunning = $true
    $overlapJson = Read-Shadow $overlap (Join-Path $root 'overlap.json') $source
    Assert-True ($overlapJson.Decisions.Count -eq 1 -and $overlapJson.Decisions[0].Result -eq 'OverlapRefused') 'overlapping coordinator is refused without backup or maintenance'

    $notDue = Copy-Fixture $base
    $notDue.PreviousAttemptAwakeMinute = 30
    $notDue.Opportunities = @([ordered]@{Kind='Periodic'; AwakeMinute=31; BackupResult=[ordered]@{ExitCode=0; ResultClass='Changed'}})
    $notDueJson = Read-Shadow $notDue (Join-Path $root 'not-due.json') $source
    Assert-True (@($notDueJson.Decisions | Where-Object Kind -eq 'Maintenance').Count -eq 0) 'maintenance requires a verified backup in the current shadow run'

    Expect-Throw { & $source -FixturePath $fixturePath } 'requires explicit -ReadOnly'
    Set-Content -LiteralPath $fixturePath -Value '{ malformed' -Encoding UTF8
    Expect-Throw { & $source -FixturePath $fixturePath -ReadOnly } 'unreadable or malformed'
    $missing = Join-Path $root 'missing.json'; Write-Fixture ([ordered]@{SchemaVersion=1}) $missing
    Expect-Throw { & $source -FixturePath $missing -ReadOnly } 'missing field'

    $badBoolean = Copy-Fixture $base; $badBoolean.Maintenance[0].Due = 'false'
    Expect-Throw { Read-Shadow $badBoolean (Join-Path $root 'bad-boolean.json') $source } 'must be a boolean'
    $badOverlap = Copy-Fixture $overlap; $badOverlap.Maintenance[1].Eligible = 'false'
    Expect-Throw { Read-Shadow $badOverlap (Join-Path $root 'bad-overlap.json') $source } 'must be a boolean'
    $badNotDue = Copy-Fixture $notDue; $badNotDue.Opportunities[0].BackupResult = [ordered]@{ExitCode=75; ResultClass='Failed'}
    Expect-Throw { Read-Shadow $badNotDue (Join-Path $root 'bad-not-due.json') $source } 'Unsupported backup result contract'
    $badOrder = Copy-Fixture $base; $badOrder.Opportunities = @($base.Opportunities[2], $base.Opportunities[1])
    Expect-Throw { Read-Shadow $badOrder (Join-Path $root 'bad-order.json') $source } 'nondecreasing awake minutes'
    $badLock = Copy-Fixture $lock; $badLock.Opportunities[0].BackupResult.ResultClass = 'Failed'
    Expect-Throw { Read-Shadow $badLock (Join-Path $root 'bad-lock.json') $source } 'Unsupported backup result contract'
    $mixedCounters = Copy-Fixture $lock; $mixedCounters.ConsecutiveBackupFailures = 1; $mixedCounters.ConsecutiveBackupDeferrals = 1
    Expect-Throw { Read-Shadow $mixedCounters (Join-Path $root 'mixed-counters.json') $source } 'cannot have consecutive failures and deferrals simultaneously'
    $orphanCounter = Copy-Fixture $base; $orphanCounter.ConsecutiveBackupFailures = 1
    Expect-Throw { Read-Shadow $orphanCounter (Join-Path $root 'orphan-counter.json') $source } 'health counters require a previous backup attempt'

    $mutations = @(
        [pscustomobject]@{Name='suspension-as-awake'; Old='($at - $previousAttempt -ge $interval)'; New='($at - $previousAttempt -ge $interval) -or $suspendedDays -gt 0'; Pattern='suspended days do not change due decisions or health'; Fixture=$base; Check={ param($j) & $contracts.SuspensionIndependent $json $j }},
        [pscustomobject]@{Name='lock-complete'; Old="Result = 'DeferredLock'; Due = `$true"; New="Result = 'DeferredLock'; Due = `$false"; Pattern='one lock is due but non-alerting'; Fixture=$lock; Check={ param($j) & $contracts.LockDueNonAlerting $j }},
        [pscustomobject]@{Name='nochange-as-changed'; Old="Result = `$class; Due = `$false"; New="Result = 'Changed'; Due = `$false"; Pattern='no-change success distinctly'; Fixture=$base; Check={ param($j) & $contracts.NoChangeDistinct $j }},
        [pscustomobject]@{Name='two-maintenance'; Old='Select-Object -First 1'; New='Select-Object -First 2'; Pattern='maintenance is serialized'; Fixture=$base; Check={ param($j) & $contracts.MaintenanceSerialized $j }},
        [pscustomobject]@{Name='threshold-off-by-one'; Old='$consecutiveFailures -ge $failureThreshold -or $consecutiveDeferrals -ge $deferralThreshold'; New='$consecutiveFailures -gt $failureThreshold -or $consecutiveDeferrals -gt $deferralThreshold'; Pattern='deferral threshold crosses on a later invocation'; Fixture=$secondLock; Check={ param($j) & $contracts.ThresholdBoundary $j }},
        [pscustomobject]@{Name='success-does-not-reset'; Old="{ `$_ -in @('Changed','NoChange') } {`n                `$consecutiveFailures = 0"; New="{ `$_ -in @('Changed','NoChange') } {`n                `$consecutiveFailures = `$consecutiveFailures"; Pattern='successful no-change attempt clears prior failure state'; Fixture=$recovery; Check={ param($j) & $contracts.RecoveryResets $j }}
    )
    foreach ($mutation in $mutations) {
        $mutationRoot = Join-Path $root $mutation.Name
        New-Item -ItemType Directory -Path $mutationRoot | Out-Null
        $mutatedSource = Join-Path $mutationRoot 'Invoke.ps1'
        Copy-Item -LiteralPath $common -Destination (Join-Path $mutationRoot 'WslHomeRestic.Common.ps1')
        $originalText = Get-Content -LiteralPath $source -Raw
        $text = $originalText.Replace($mutation.Old, $mutation.New)
        if ($text -eq $originalText) { throw "Mutation source replacement did not apply: $($mutation.Name)" }
        Set-Content -LiteralPath $mutatedSource -Value $text -Encoding UTF8
        $freshFixture = Join-Path $mutationRoot 'fixture.json'
        Write-Fixture $mutation.Fixture $freshFixture
        try { $mutatedJson = & $mutatedSource -FixturePath $freshFixture -ReadOnly | ConvertFrom-Json }
        catch { throw "Mutation harness failure for $($mutation.Name): $($_.Exception.Message)" }
        Assert-True (-not (& $mutation.Check $mutatedJson)) "$($mutation.Name) mutation killed at retained contract: $($mutation.Pattern)"
    }
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output "WslHomeSchedulingShadow tests passed: $script:tests assertions"
