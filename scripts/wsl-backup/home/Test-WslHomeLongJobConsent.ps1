#requires -Version 7.0
[CmdletBinding()]
param([string] $CandidatePath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$script:tests = 0

function Assert-True { param([bool]$Condition,[string]$Message) $script:tests++; if (-not $Condition) { throw "ASSERTION FAILED: $Message" } }
function Invoke-Child {
    param([string]$Script,[hashtable]$Arguments)
    $psi = [Diagnostics.ProcessStartInfo]::new((Get-Command pwsh.exe -CommandType Application | Select-Object -First 1).Source)
    $psi.UseShellExecute=$false; $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
    foreach ($item in @('-NoLogo','-NoProfile','-NonInteractive','-File',$Script)) { $psi.ArgumentList.Add($item) }
    foreach ($entry in $Arguments.GetEnumerator()) {
        if ($null -eq $entry.Value) { continue }
        $psi.ArgumentList.Add("-$($entry.Key)"); $psi.ArgumentList.Add([string]$entry.Value)
    }
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$psi; $null=$process.Start()
    $stdout=$process.StandardOutput.ReadToEnd(); $stderr=$process.StandardError.ReadToEnd()
    if (-not $process.WaitForExit(30000)) { $process.Kill($true); throw "Child timed out: $Script" }
    [pscustomobject]@{ExitCode=$process.ExitCode;Stdout=$stdout.Trim();Stderr=$stderr.Trim()}
}
function Read-JsonResult {
    param($Result,[string]$Description)
    if ($Result.ExitCode -ne 0) { throw "ASSERTION FAILED: $Description exits successfully: $($Result.Stderr)" }
    $script:tests++
    try { $Result.Stdout | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "ASSERTION FAILED: $Description emits JSON: $($Result.Stdout) $($Result.Stderr)" }
}
function Set-Text { param([string]$Path,[string]$Value) Set-Content -LiteralPath $Path -Value $Value -Encoding UTF8 }
function Get-Count { param([string]$Path) if (Test-Path -LiteralPath $Path) { @(Get-Content -LiteralPath $Path).Count } else { 0 } }

$candidate = if ([string]::IsNullOrWhiteSpace($CandidatePath)) { Join-Path $PSScriptRoot 'Invoke-WslHomeLongJobConsent.ps1' } else { $CandidatePath }
$root = Join-Path ([IO.Path]::GetTempPath()) ('wsl-long-job-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $policy = Join-Path $root 'policy.json'
    $policyObject = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'WslHomeLongJobPolicy.json') -Raw | ConvertFrom-Json
    $policyObject.Operations = @($policyObject.Operations | Where-Object Id -eq 'prune')
    $policyObject.Operations[0].CommandFile = 'fixed-operation.ps1'
    $policyObject.Operations[0].DisplayName = 'Prune evidence; check-read-data; Remove-Item C:\important'
    $policyObject | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $policy -Encoding UTF8

    $interactiveValue=Join-Path $root 'interactive.txt'; $powerValue=Join-Path $root 'power.txt'; $decisionValue=Join-Path $root 'decision.txt'
    $resultValue=Join-Path $root 'result.txt'; $clockValue=Join-Path $root 'clock.txt'; $promptLog=Join-Path $root 'prompt.log'
    $commandLog=Join-Path $root 'command.log'; $sleepLog=Join-Path $root 'sleep.log'
    Set-Text $interactiveValue 'true'; Set-Text $powerValue 'true'; Set-Text $decisionValue 'Yes'; Set-Text $resultValue 'Success'; Set-Text $clockValue "10`n22"

    $interactive=Join-Path $root 'interactive.ps1'
    @"
param([string]`$Action)
[ordered]@{Interactive=[bool]::Parse((Get-Content -LiteralPath '$($interactiveValue.Replace("'","''"))' -Raw).Trim())} | ConvertTo-Json -Compress
"@ | Set-Content -LiteralPath $interactive -Encoding UTF8
    $power=Join-Path $root 'power.ps1'
    @"
param([string]`$Action)
[ordered]@{OnAc=[bool]::Parse((Get-Content -LiteralPath '$($powerValue.Replace("'","''"))' -Raw).Trim())} | ConvertTo-Json -Compress
"@ | Set-Content -LiteralPath $power -Encoding UTF8
    $prompt=Join-Path $root 'prompt.ps1'
    @"
param([string]`$PromptPath,[int]`$TimeoutSeconds)
`$facts=Get-Content -LiteralPath `$PromptPath -Raw | ConvertFrom-Json
Add-Content -LiteralPath '$($promptLog.Replace("'","''"))' -Value (`$facts | ConvertTo-Json -Compress)
[ordered]@{Decision=(Get-Content -LiteralPath '$($decisionValue.Replace("'","''"))' -Raw).Trim()} | ConvertTo-Json -Compress
"@ | Set-Content -LiteralPath $prompt -Encoding UTF8
    $sleep=Join-Path $root 'sleep.ps1'
    @"
param([string]`$Action,[string]`$Scope,[string]`$Token)
Add-Content -LiteralPath '$($sleepLog.Replace("'","''"))' -Value "`$Action|`$Scope|`$Token"
if (`$Action -eq 'Acquire') { [ordered]@{Token='fixture-token'} | ConvertTo-Json -Compress } else { [ordered]@{Released=`$true} | ConvertTo-Json -Compress }
"@ | Set-Content -LiteralPath $sleep -Encoding UTF8
    $clock=Join-Path $root 'clock.ps1'
    @"
param([string]`$Action)
`$values=@(Get-Content -LiteralPath '$($clockValue.Replace("'","''"))'); `$value=`$values[0]
if (`$values.Count -gt 1) { Set-Content -LiteralPath '$($clockValue.Replace("'","''"))' -Value `$values[1..(`$values.Count-1)] } else { Set-Content -LiteralPath '$($clockValue.Replace("'","''"))' -Value `$value }
[ordered]@{Seconds=[double]`$value} | ConvertTo-Json -Compress
"@ | Set-Content -LiteralPath $clock -Encoding UTF8
    $command=Join-Path $root 'fixed-operation.ps1'
    @"
param([string]`$OperationId)
Add-Content -LiteralPath '$($commandLog.Replace("'","''"))' -Value `$OperationId
[ordered]@{Result=(Get-Content -LiteralPath '$($resultValue.Replace("'","''"))' -Raw).Trim()} | ConvertTo-Json -Compress
"@ | Set-Content -LiteralPath $command -Encoding UTF8
    $alternateCommand=Join-Path $root 'alternate-operation.ps1'
    @"
param([string]`$OperationId)
Add-Content -LiteralPath '$($commandLog.Replace("'","''"))' -Value 'alternate-operation'
[ordered]@{Result='Success'} | ConvertTo-Json -Compress
"@ | Set-Content -LiteralPath $alternateCommand -Encoding UTF8

    function Invoke-Candidate {
        param([string]$State,[string]$Action='Offer',[datetime]$Now=([datetime]'2026-08-27T10:00:00Z'))
        $candidateArguments=[ordered]@{Action=$Action;PolicyPath=$policy;StatePath=$State;Now=$Now.ToString('o')}
        if ($Action -eq 'Offer') {
            $candidateArguments.OperationId='prune';$candidateArguments.InteractiveAdapterPath=$interactive;$candidateArguments.PowerAdapterPath=$power
            $candidateArguments.PromptAdapterPath=$prompt;$candidateArguments.SleepInhibitionAdapterPath=$sleep;$candidateArguments.MonotonicClockAdapterPath=$clock
        }
        Invoke-Child $candidate $candidateArguments
    }
    function New-TestState { param([string]$Name) $path=Join-Path $root "$Name-state.json"; $null=Read-JsonResult (Invoke-Candidate $path Initialize) "$Name initialization"; $path }

    $yesState=New-TestState 'yes'
    $yes=Read-JsonResult (Invoke-Candidate $yesState Offer ([datetime]'2026-08-27T10:00:00Z')) 'approved operation'
    Assert-True ($yes.Status -eq 'Success' -and $yes.CommandRan -and -not $yes.Due) 'Yes runs exactly the displayed fixed operation'
    Assert-True ((Get-Content -LiteralPath $commandLog -Raw).Trim() -eq 'prune' -and $yes.OperationId -eq 'prune') 'fixed reviewed operation identity reaches the command unchanged'
    Assert-True ($yes.OfferedOperations -eq 1 -and (Get-Count $commandLog) -eq 1) 'at most one consent-required operation is offered and run'
    Assert-True ((Get-Content -LiteralPath $promptLog -Raw) -match 'Remove-Item' -and (Get-Count $commandLog) -eq 1) 'dynamic prompt content cannot inject or select a command'
    Assert-True ($yes.MeasuredDurationSeconds -eq 12 -and $yes.ConservativeDurationSeconds -eq 15) 'duration recording is deterministic and conservative'
    Assert-True (@(Get-Content -LiteralPath $sleepLog)[0] -eq 'Acquire|IdleSleepOnly|') 'idle-sleep inhibition starts only after approval and preserves explicit user intent'
    Assert-True (@(Get-Content -LiteralPath $sleepLog)[1] -eq 'Release|IdleSleepOnly|fixture-token') 'idle-sleep inhibition is released after approved success'

    foreach ($decision in @('No','TimedOut','Ignored')) {
        Set-Text $decisionValue $decision; Set-Text $interactiveValue 'true'; Set-Text $powerValue 'true'
        $state=New-TestState $decision; $before=Get-Count $commandLog
        $result=Read-JsonResult (Invoke-Candidate $state Offer ([datetime]'2026-08-27T11:00:00Z')) "$decision decision"
        Assert-True (-not $result.CommandRan -and $result.Due -and (Get-Count $commandLog) -eq $before) "$decision never runs the operation and keeps it due"
        Assert-True ([datetimeoffset]$result.SnoozeUntil -eq [datetimeoffset]'2026-08-28T11:00:00Z') "$decision snoozes prompts for exactly 24 hours"
    }

    Set-Text $decisionValue 'Yes'; Set-Text $interactiveValue 'false'; Set-Text $powerValue 'true'
    $sessionState=New-TestState 'session'; $before=Get-Count $commandLog; $beforePrompt=Get-Count $promptLog
    $session=Read-JsonResult (Invoke-Candidate $sessionState Offer) 'absent interactive session'
    Assert-True ($session.Status -eq 'DeferredNoInteractiveSession' -and (Get-Count $commandLog) -eq $before -and (Get-Count $promptLog) -eq $beforePrompt) 'absent interactive session defers before prompting or running'
    Set-Text $interactiveValue 'true'; Set-Text $powerValue 'false'
    $powerState=New-TestState 'power'; $before=Get-Count $commandLog; $beforePrompt=Get-Count $promptLog
    $blocked=Read-JsonResult (Invoke-Candidate $powerState Offer) 'blocked battery path'
    Assert-True ($blocked.Status -eq 'DeferredPower' -and (Get-Count $commandLog) -eq $before -and (Get-Count $promptLog) -eq $beforePrompt) 'battery policy prevents prompting and running'

    Set-Text $powerValue 'true'; Set-Text $decisionValue 'No'
    $snoozeState=New-TestState 'snooze'; $null=Read-JsonResult (Invoke-Candidate $snoozeState Offer ([datetime]'2026-08-27T12:00:00Z')) 'snooze start'
    $promptBefore=Get-Count $promptLog
    $early=Read-JsonResult (Invoke-Candidate $snoozeState Offer ([datetime]'2026-08-28T11:59:59Z')) 'pre-boundary snooze'
    Assert-True ($early.Status -eq 'Snoozed' -and (Get-Count $promptLog) -eq $promptBefore) 'snooze suppresses prompts just before its exact boundary'
    Set-Text $decisionValue 'Yes'; Set-Text $clockValue "30`n38"
    $boundary=Read-JsonResult (Invoke-Candidate $snoozeState Offer ([datetime]'2026-08-28T12:00:00Z')) 'exact snooze boundary'
    Assert-True ($boundary.Status -eq 'Success' -and (Get-Count $promptLog) -eq $promptBefore+1) "snoozed work is reoffered exactly at the boundary (status=$($boundary.Status), prompts=$(Get-Count $promptLog), before=$promptBefore)"

    $duplicateState=New-TestState 'duplicate'; $held=[IO.FileStream]::new("$duplicateState.lock",[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try { $duplicate=Read-JsonResult (Invoke-Candidate $duplicateState Offer) 'overlap refusal' } finally { $held.Dispose() }
    Assert-True ($duplicate.Status -eq 'OverlapRefused' -and $duplicate.OfferedOperations -eq 0 -and -not $duplicate.CommandRan) 'duplicate prompts are prevented by the cross-process lock'

    foreach ($resultClass in @('Success','Failed','Interrupted')) {
        Set-Text $resultValue $resultClass; Set-Text $decisionValue 'Yes'; Set-Text $clockValue "50`n55"
        $caseState=New-TestState "release-$resultClass"; $sleepBefore=Get-Count $sleepLog
        $case=Read-JsonResult (Invoke-Candidate $caseState Offer) "$resultClass execution"
        $sleepLines=@(Get-Content -LiteralPath $sleepLog | Select-Object -Skip $sleepBefore)
        Assert-True ($sleepLines.Count -eq 2 -and $sleepLines[0] -match '^Acquire' -and $sleepLines[1] -match '^Release') "idle-sleep inhibition is released after $resultClass"
        if ($resultClass -ne 'Success') { Assert-True ($case.Due -and $case.Status -eq $resultClass) "$resultClass work remains due" }
    }

    Set-Text $resultValue 'Failed'; Set-Text $clockValue "100`n112"
    $durationState=New-TestState 'duration'; $null=Read-JsonResult (Invoke-Candidate $durationState Offer) 'first duration evidence'
    Set-Text $resultValue 'Success'; Set-Text $clockValue "200`n208"
    $second=Read-JsonResult (Invoke-Candidate $durationState Offer ([datetime]'2026-08-27T13:00:00Z')) 'second duration evidence'
    $history=@($second.State.Operations.prune.DurationSecondsHistory)
    Assert-True ($history.Count -eq 2 -and $history[0] -eq 12 -and $history[1] -eq 8 -and $second.ConservativeDurationSeconds -eq 15) 'duration history retains measured evidence and a conservative maximum margin'

    $trackedUi=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-WslHomeConsentUi.ps1') -Raw
    Assert-True ($trackedUi -match 'Run it now\?' -and $trackedUi -match "Decision='TimedOut'" -and $trackedUi -match '\[Console\]::ReadLine' -and $trackedUi -match "'Yes'.*'No'") 'tracked PowerShell 7 UI implements a timed Yes/No prompt'
    Assert-True ($trackedUi -match '\[Console\]::Error\.WriteLine' -and (Get-Content -LiteralPath $candidate -Raw) -match "'Consent prompt'.*-VisiblePrompt") 'visible prompt facts remain separate from the machine-readable decision result'
    Assert-True (@(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object FullName -notlike "$root*").Count -eq 0) 'all Phase 3 fixtures remain inside the disposable root'
    Assert-True ((Get-Content -LiteralPath $candidate -Raw) -notmatch 'wsl\.exe|ScheduledTask|msg\.exe|active-failure|backup-wsl-home') 'candidate contains no WSL, task, notification, marker, or deployed-command invocation'

    Write-Output "WslHomeLongJobConsent retained tests passed: $script:tests assertions"
} finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
