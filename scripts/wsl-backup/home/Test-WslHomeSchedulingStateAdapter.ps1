#requires -Version 7.0
[CmdletBinding()]
param([string] $AdapterPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$script:tests = 0

function Assert-True {
    param([bool] $Condition, [string] $Message)
    $script:tests++
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}
function Quote-SourceLiteral { param([string] $Value) "'" + $Value.Replace("'", "''") + "'" }
function Invoke-Child {
    param([string] $Script, [hashtable] $Arguments)
    $psi = [Diagnostics.ProcessStartInfo]::new((Get-Command pwsh.exe -CommandType Application | Select-Object -First 1).Source)
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($item in @('-NoLogo','-NoProfile','-NonInteractive','-File',$Script)) { $psi.ArgumentList.Add($item) }
    foreach ($entry in $Arguments.GetEnumerator()) {
        if ($entry.Value -is [bool]) { if ($entry.Value) { $psi.ArgumentList.Add("-$($entry.Key)") }; continue }
        if ($null -eq $entry.Value) { continue }
        $psi.ArgumentList.Add("-$($entry.Key)")
        $psi.ArgumentList.Add([string]$entry.Value)
    }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $psi
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    if (-not $process.WaitForExit(20000)) { $process.Kill($true); throw "Child timed out: $Script" }
    [pscustomobject]@{ ExitCode=$process.ExitCode; Stdout=$stdout.Trim(); Stderr=$stderr.Trim() }
}
function Invoke-Adapter {
    param([string] $Adapter, [string] $Action, [string] $Policy, [string] $State,
        [string] $Opportunity, [long] $AwakeMinute, [string] $Backup, [datetime] $Now,
        [string] $FaultPoint='None', [string] $Diagnostic)
    $adapterArguments = [ordered]@{Action=$Action;PolicyPath=$Policy;StatePath=$State}
    if ($Opportunity) { $adapterArguments.Opportunity=$Opportunity; $adapterArguments.AwakeMinute=$AwakeMinute }
    if ($Backup) { $adapterArguments.BackupCommandPath=$Backup }
    if ($Now) { $adapterArguments.Now=$Now.ToString('o') }
    if ($FaultPoint -ne 'None') { $adapterArguments.FaultPoint=$FaultPoint }
    if ($Diagnostic) { $adapterArguments.DiagnosticPath=$Diagnostic }
    Invoke-Child $Adapter $adapterArguments
}
function Read-OutputJson {
    param($Result, [string] $Description)
    Assert-True ($Result.ExitCode -eq 0) "$Description exits successfully"
    try { $Result.Stdout | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "ASSERTION FAILED: $Description emits JSON; stdout='$($Result.Stdout)' stderr='$($Result.Stderr)'" }
}
function Read-State { param([string] $Path) Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
function Write-Policy { param($Policy, [string] $Path) $Policy | ConvertTo-Json | Set-Content -LiteralPath $Path -Encoding UTF8 }
function Copy-Policy { param($Policy) $Policy | ConvertTo-Json | ConvertFrom-Json -AsHashtable }
function Write-FakeBackup {
    param([string] $Path, [string] $LogPath, [string] $ResultClass, [int] $ExitCode)
    $scriptText = @"
#requires -Version 7.0
Add-Content -LiteralPath $(Quote-SourceLiteral $LogPath) -Value $(Quote-SourceLiteral $ResultClass)
[ordered]@{ResultClass=$(Quote-SourceLiteral $ResultClass)} | ConvertTo-Json -Compress
exit $ExitCode
"@
    Set-Content -LiteralPath $Path -Value $scriptText -Encoding UTF8
}
function Get-LogCount { param([string] $Path) if (Test-Path -LiteralPath $Path) { @(Get-Content -LiteralPath $Path).Count } else { 0 } }
function Initialize-State {
    param([string] $Adapter, [string] $Policy, [string] $State)
    $result = Invoke-Adapter $Adapter Initialize $Policy $State $null 0 $null ([datetime]'2026-08-27T08:00:00Z')
    $json = Read-OutputJson $result 'state initialization'
    Assert-True ($json.Status -eq 'Initialized' -and $json.Generation -eq 0) 'initial state has generation zero'
}

$adapter = if ([string]::IsNullOrWhiteSpace($AdapterPath)) {
    Join-Path $PSScriptRoot 'Invoke-WslHomeSchedulingStateAdapter.ps1'
} else { $AdapterPath }
$policySource = Join-Path $PSScriptRoot 'WslHomeSchedulingPolicy.json'
$root = Join-Path ([IO.Path]::GetTempPath()) ('wsl-state-adapter-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $policy = Join-Path $root 'policy.json'; Copy-Item -LiteralPath $policySource -Destination $policy
    $approvedPolicy = Get-Content -LiteralPath $policy -Raw | ConvertFrom-Json -AsHashtable
    $state = Join-Path $root 'state.json'
    $diagnostic = Join-Path $root 'diagnostic.json'
    $log = Join-Path $root 'backup.log'
    $changed = Join-Path $root 'changed.ps1'; Write-FakeBackup $changed $log Changed 0
    $noChange = Join-Path $root 'nochange.ps1'; Write-FakeBackup $noChange $log NoChange 0
    $failed = Join-Path $root 'failed.ps1'; Write-FakeBackup $failed $log Failed 2
    $locked = Join-Path $root 'locked.ps1'; Write-FakeBackup $locked $log Lock 75
    $mismatch = Join-Path $root 'mismatch.ps1'; Write-FakeBackup $mismatch $log Failed 75

    Initialize-State $adapter $policy $state
    $ready = Read-OutputJson (Invoke-Adapter $adapter ReadStatus $policy $state $null 0 $null ([datetime]'2026-08-27T08:00:00Z')) 'read status'
    Assert-True ($ready.State.SchemaVersion -eq 2 -and $ready.State.PolicySha256 -eq $ready.PolicySha256) 'strict state records schema and reviewed policy hash'
    Assert-True ($null -eq $ready.State.PendingAttempt -and $ready.State.Generation -eq 0) 'initial state has no pending attempt'
    $dryRun = Join-Path $PSScriptRoot 'Invoke-WslHomeSchedulingDryRun.ps1'
    $dryRunResult = Invoke-Child $dryRun ([ordered]@{ReadOnly=$true;StatePath=$state;Now='2026-08-27T08:00:00Z'})
    $dryRunJson = Read-OutputJson $dryRunResult 'shared scheduling dry-run reads adapter schema'
    Assert-True ($dryRunJson.State -eq 'Ready') 'shared scheduling dry-run accepts adapter state schema 2'

    $firstFailure = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Resume 0 $failed ([datetime]'2026-08-27T08:00:00Z')) 'first failure'
    Assert-True ($firstFailure.Result -eq 'Failed' -and -not $firstFailure.Notify) 'first real failure is non-alerting'
    Assert-True ($firstFailure.State.ConsecutiveBackupFailures -eq 1 -and $firstFailure.State.ConsecutiveBackupDeferrals -eq 0) 'failure counter persists after first process'
    Assert-True (-not $firstFailure.BackupGateSatisfied) 'failure blocks the backup-before-maintenance gate'

    $sleepGap = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Periodic 1 $changed ([datetime]'2026-09-17T08:00:00Z')) 'weeks-suspended not-due event'
    Assert-True ($sleepGap.Status -eq 'NotDue' -and (Get-LogCount $log) -eq 1) 'weeks of suspension do not create an awake-time attempt'
    $sleepState = Read-State $state
    Assert-True ($sleepState.ConsecutiveBackupFailures -eq 1 -and $sleepState.LastAttemptAwakeMinute -eq 0) 'suspension neither increments nor resets health state'

    $secondFailure = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Resume 1 $failed ([datetime]'2026-09-17T08:01:00Z')) 'second failure after suspension'
    Assert-True ($secondFailure.State.ConsecutiveBackupFailures -eq 2 -and $secondFailure.Notify) 'second eligible failure warns even when attempts are weeks apart'
    $thirdFailure = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Periodic 16 $failed ([datetime]'2026-09-17T13:00:59Z')) 'suppressed repeated failure'
    Assert-True (-not $thirdFailure.Notify) 'same episode notification is suppressed before six hours'
    $fourthFailure = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Periodic 31 $failed ([datetime]'2026-09-17T14:01:00Z')) 'six-hour repeated failure'
    Assert-True ($fourthFailure.Notify) 'same episode notification resumes exactly at six hours'

    $success = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Periodic 46 $noChange ([datetime]'2026-09-17T14:02:00Z')) 'successful no-change recovery'
    Assert-True ($success.BackupGateSatisfied -and $success.State.ConsecutiveBackupFailures -eq 0 -and $success.State.ConsecutiveBackupDeferrals -eq 0) 'no-change success resets both counters and opens backup gate'
    Assert-True ($null -eq $success.State.NotificationEpisode.Signature) 'success ends the notification episode'
    $newFailure1 = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Periodic 61 $failed ([datetime]'2026-09-17T14:03:00Z')) 'new episode first failure'
    $newFailure2 = Read-OutputJson (Invoke-Adapter $adapter Run $policy $state Periodic 76 $failed ([datetime]'2026-09-17T14:04:00Z')) 'new episode second failure'
    Assert-True (-not $newFailure1.Notify -and $newFailure2.Notify) 'new episode notifies at its threshold inside the old six-hour window'

    $lockState = Join-Path $root 'lock-state.json'; Initialize-State $adapter $policy $lockState
    $firstLock = Read-OutputJson (Invoke-Adapter $adapter Run $policy $lockState Resume 0 $locked ([datetime]'2026-08-27T09:00:00Z')) 'first lock deferral'
    $secondLock = Read-OutputJson (Invoke-Adapter $adapter Run $policy $lockState Periodic 15 $locked ([datetime]'2026-08-27T09:15:00Z')) 'second lock deferral'
    Assert-True ($firstLock.Result -eq 'DeferredLock' -and -not $firstLock.Notify -and -not $firstLock.BackupGateSatisfied) 'first lock remains non-alerting and blocks maintenance'
    Assert-True ($secondLock.State.ConsecutiveBackupDeferrals -eq 2 -and $secondLock.Notify -and -not $secondLock.BackupGateSatisfied) 'second consecutive lock deferral warns and remains blocked'

    $overlapLock = [IO.FileStream]::new("$lockState.lock", [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try { $overlap = Read-OutputJson (Invoke-Adapter $adapter Run $policy $lockState Resume 16 $changed ([datetime]'2026-08-27T09:16:00Z')) 'overlap refusal' }
    finally { $overlapLock.Dispose() }
    Assert-True ($overlap.Status -eq 'OverlapRefused' -and -not $overlap.BackupGateSatisfied) 'overlapping adapter process is refused'

    $invalidPolicies = @(
        @{Name='string threshold'; Mutate={param($p) $p.FailureWarningThreshold='2'}; Pattern='JSON integer'},
        @{Name='null threshold'; Mutate={param($p) $p.FailureWarningThreshold=$null}; Pattern='JSON integer'},
        @{Name='missing threshold'; Mutate={param($p) $null=$p.Remove('FailureWarningThreshold')}; Pattern='missing field'},
        @{Name='below threshold'; Mutate={param($p) $p.FailureWarningThreshold=1}; Pattern='between 2 and 3'},
        @{Name='above threshold'; Mutate={param($p) $p.FailureWarningThreshold=4}; Pattern='between 2 and 3'},
        @{Name='fractional threshold'; Mutate={param($p) $p.DeferralWarningThreshold=2.5}; Pattern='JSON integer'},
        @{Name='wrong interval'; Mutate={param($p) $p.PeriodicIntervalMinutes=16}; Pattern='between 15 and 15'},
        @{Name='wrong suppression'; Mutate={param($p) $p.NotificationSuppressionHours=7}; Pattern='between 6 and 6'},
        @{Name='unknown field'; Mutate={param($p) $p.Unexpected=$true}; Pattern='unknown field'},
        @{Name='unknown schema'; Mutate={param($p) $p.SchemaVersion=99}; Pattern='between 1 and 1'}
    )
    foreach ($case in $invalidPolicies) {
        $badPolicy = Join-Path $root ("policy-$($case.Name.Replace(' ','-')).json")
        $value = Copy-Policy $approvedPolicy; & $case.Mutate $value; Write-Policy $value $badPolicy
        $before = Get-LogCount $log
        $bad = Invoke-Adapter $adapter Run $badPolicy $state Resume 100 $changed ([datetime]'2026-09-17T15:00:00Z')
        Assert-True ($bad.ExitCode -ne 0 -and $bad.Stderr -match $case.Pattern) "policy rejects $($case.Name) at intended seam"
        Assert-True ((Get-LogCount $log) -eq $before) "$($case.Name) invokes no backup command"
    }
    $duplicatePolicy = Join-Path $root 'policy-duplicate.json'
    Set-Content -LiteralPath $duplicatePolicy -Encoding UTF8 -Value '{"SchemaVersion":1,"SchemaVersion":1,"PeriodicIntervalMinutes":15,"FailureWarningThreshold":2,"DeferralWarningThreshold":2,"NotificationSuppressionHours":6}'
    $duplicate = Invoke-Adapter $adapter Run $duplicatePolicy $state Resume 100 $changed ([datetime]'2026-09-17T15:00:00Z')
    Assert-True ($duplicate.ExitCode -ne 0 -and $duplicate.Stderr -match 'duplicate fields') 'policy rejects duplicate JSON fields'
    $malformedPolicy = Join-Path $root 'policy-malformed.json'; Set-Content -LiteralPath $malformedPolicy -Value '{ malformed' -Encoding UTF8
    $malformedPolicyResult = Invoke-Adapter $adapter Run $malformedPolicy $state Resume 100 $changed ([datetime]'2026-09-17T15:00:00Z')
    Assert-True ($malformedPolicyResult.ExitCode -ne 0 -and $malformedPolicyResult.Stderr -match 'unreadable or malformed') 'policy rejects malformed JSON before backup'
    $beforeAbsent = Get-LogCount $log
    $absentPolicyResult = Invoke-Adapter $adapter Run (Join-Path $root 'absent-policy.json') $state Resume 100 $changed ([datetime]'2026-09-17T15:00:00Z')
    Assert-True ($absentPolicyResult.ExitCode -ne 0 -and $absentPolicyResult.Stderr -match 'policy is absent') 'policy rejects an absent file before backup'
    Assert-True ((Get-LogCount $log) -eq $beforeAbsent) 'malformed and absent policies invoke no backup command'

    $mismatchState = Join-Path $root 'mismatch-state.json'; Initialize-State $adapter $policy $mismatchState
    $mismatchResult = Invoke-Adapter $adapter Run $policy $mismatchState Resume 0 $mismatch ([datetime]'2026-08-27T10:00:00Z')
    Assert-True ($mismatchResult.ExitCode -ne 0 -and $mismatchResult.Stderr -match 'Unsupported backup result contract') 'exit/result mismatch fails at strict result seam'
    $mismatchPersisted = Read-State $mismatchState
    Assert-True ($null -ne $mismatchPersisted.PendingAttempt -and $mismatchPersisted.ConsecutiveBackupFailures -eq 0) 'result mismatch leaves pending work without invented failure or success'

    $interruptedState = Join-Path $root 'interrupted-state.json'; Initialize-State $adapter $policy $interruptedState
    $beforeInterrupted = Get-LogCount $log
    $interrupted = Invoke-Adapter $adapter Run $policy $interruptedState Resume 0 $changed ([datetime]'2026-08-27T11:00:00Z') 'AfterBackup'
    Assert-True ($interrupted.ExitCode -ne 0) 'forced interruption after backup exits abnormally'
    $pending = Read-State $interruptedState
    Assert-True ($null -ne $pending.PendingAttempt -and $null -eq $pending.LastCoordinatorSuccess) 'interruption never infers backup success'
    $recovered = Read-OutputJson (Invoke-Adapter $adapter Run $policy $interruptedState Resume 0 $noChange ([datetime]'2026-08-27T11:01:00Z')) 'interrupted attempt recovery'
    Assert-True ((Get-LogCount $log) -eq $beforeInterrupted + 2) 'interrupted attempt is retried exactly once on the later opportunity'
    Assert-True ($null -eq $recovered.State.PendingAttempt -and $null -ne $recovered.State.Recovery.LastInterruptedAttemptId) 'retry records interrupted identity and commits a classified result'

    foreach ($point in @('Pending:BeforeTempWrite','Pending:AfterTempWrite','Pending:AfterFlush','Pending:BeforeReplace')) {
        $faultState = Join-Path $root ("fault-$($point.Replace(':','-')).json"); Initialize-State $adapter $policy $faultState
        $fault = Invoke-Adapter $adapter Run $policy $faultState Resume 0 $changed ([datetime]'2026-08-27T12:00:00Z') $point
        Assert-True ($fault.ExitCode -ne 0) "$point terminates the child process"
        $valid = Read-OutputJson (Invoke-Adapter $adapter ReadStatus $policy $faultState $null 0 $null ([datetime]'2026-08-27T12:01:00Z')) "$point old-state recovery"
        Assert-True ($valid.State.SchemaVersion -eq 2) "$point leaves the prior complete state readable"
        $tempPattern = '.{0}.*.tmp' -f [IO.Path]::GetFileName($faultState)
        Assert-True (@(Get-ChildItem -LiteralPath $root -Filter $tempPattern -File).Count -eq 0) "$point abandoned temporary is explicitly cleaned"
    }
    $finalBefore = Join-Path $root 'fault-final-before.json'; Initialize-State $adapter $policy $finalBefore
    $null = Invoke-Adapter $adapter Run $policy $finalBefore Resume 0 $changed ([datetime]'2026-08-27T12:30:00Z') 'Final:BeforeReplace'
    $finalBeforeState = Read-State $finalBefore
    Assert-True ($null -ne $finalBeforeState.PendingAttempt -and $null -eq $finalBeforeState.LastCoordinatorSuccess) 'fault before final replace preserves complete pending generation'
    $finalAfter = Join-Path $root 'fault-final-after.json'; Initialize-State $adapter $policy $finalAfter
    $null = Invoke-Adapter $adapter Run $policy $finalAfter Resume 0 $changed ([datetime]'2026-08-27T12:31:00Z') 'Final:AfterReplace'
    $finalAfterState = Read-State $finalAfter
    Assert-True ($null -eq $finalAfterState.PendingAttempt -and $null -ne $finalAfterState.LastCoordinatorSuccess) 'fault after final replace leaves complete new generation authoritative'

    $corruptState = Join-Path $root 'corrupt-state.json'; Initialize-State $adapter $policy $corruptState
    Set-Content -LiteralPath $corruptState -Value '{ malformed' -Encoding UTF8
    $corruptBefore = Get-Content -LiteralPath $corruptState -Raw
    $beforeCorrupt = Get-LogCount $log
    $corruptDiagnostic = Join-Path $root 'corrupt-diagnostic.json'
    $corrupt = Invoke-Adapter $adapter Run $policy $corruptState Resume 0 $changed ([datetime]'2026-08-27T13:00:00Z') 'None' $corruptDiagnostic
    Assert-True ($corrupt.ExitCode -ne 0 -and $corrupt.Stderr -match 'unreadable or malformed') 'malformed state fails closed'
    Assert-True ((Get-Content -LiteralPath $corruptState -Raw) -eq $corruptBefore -and (Get-LogCount $log) -eq $beforeCorrupt) 'malformed state is preserved and invokes no backup'
    $firstDiagnostic = Get-Content -LiteralPath $corruptDiagnostic -Raw | ConvertFrom-Json
    Assert-True ($firstDiagnostic.Reason -match 'malformed' -and $firstDiagnostic.Notify) 'malformed state emits its first diagnostic notification record'
    $null = Invoke-Adapter $adapter Run $policy $corruptState Resume 0 $changed ([datetime]'2026-08-27T14:00:00Z') 'None' $corruptDiagnostic
    $suppressedDiagnostic = Get-Content -LiteralPath $corruptDiagnostic -Raw | ConvertFrom-Json
    Assert-True (-not $suppressedDiagnostic.Notify -and $suppressedDiagnostic.LastNotifiedAt -eq $firstDiagnostic.LastNotifiedAt) 'identical state diagnostic is suppressed before six hours'
    $null = Invoke-Adapter $adapter Run $policy $corruptState Resume 0 $changed ([datetime]'2026-08-27T19:00:00Z') 'None' $corruptDiagnostic
    Assert-True ((Get-Content -LiteralPath $corruptDiagnostic -Raw | ConvertFrom-Json).Notify) 'identical state diagnostic resumes exactly at six hours'

    $duplicateState = Join-Path $root 'duplicate-state.json'; Initialize-State $adapter $policy $duplicateState
    $duplicateStateText = (Get-Content -LiteralPath $duplicateState -Raw).Replace('"Signature":null', '"Signature":null,"Signature":null')
    Set-Content -LiteralPath $duplicateState -Value $duplicateStateText -Encoding UTF8
    $duplicateStateResult = Invoke-Adapter $adapter Run $policy $duplicateState Resume 0 $changed ([datetime]'2026-08-27T19:01:00Z')
    Assert-True ($duplicateStateResult.ExitCode -ne 0 -and $duplicateStateResult.Stderr -match 'duplicate fields') 'state rejects duplicate nested JSON fields'

    $unknownState = Join-Path $root 'unknown-state.json'; Initialize-State $adapter $policy $unknownState
    $unknownObject = Read-State $unknownState; $unknownObject.SchemaVersion = 99
    $unknownObject | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $unknownState -Encoding UTF8
    $unknown = Invoke-Adapter $adapter Run $policy $unknownState Resume 0 $changed ([datetime]'2026-08-27T19:02:00Z') 'None' $corruptDiagnostic
    Assert-True ($unknown.ExitCode -ne 0 -and $unknown.Stderr -match 'between 2 and 2') 'unknown state schema fails closed'
    Assert-True ((Get-Content -LiteralPath $corruptDiagnostic -Raw | ConvertFrom-Json).Notify) 'changed state diagnostic signature notifies immediately'

    $productionTokens = 'wsl\.exe|restic|ScheduledTask|msg\.exe|active-failure|check-read-data|backup-wsl-home'
    Assert-True ((Get-Content -LiteralPath $adapter -Raw) -cnotmatch $productionTokens) 'state adapter has no WSL, Restic, task, message, marker, or production-operation adapter'
    Assert-True ((Get-Content -LiteralPath $policySource -Raw | ConvertFrom-Json).FailureWarningThreshold -eq 2) 'tracked policy contains approved failure threshold'

    Write-Output "WslHomeSchedulingStateAdapter retained tests passed: $script:tests assertions"
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
