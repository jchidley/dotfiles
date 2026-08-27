#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Initialize','Offer','ReadStatus')][string] $Action,
    [Parameter(Mandatory = $true)][string] $PolicyPath,
    [Parameter(Mandatory = $true)][string] $StatePath,
    [string] $OperationId,
    [datetime] $Now = (Get-Date),
    [string] $InteractiveAdapterPath,
    [string] $PowerAdapterPath,
    [string] $PromptAdapterPath,
    [string] $SleepInhibitionAdapterPath,
    [string] $MonotonicClockAdapterPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1')
Assert-PowerShell7

$policyFields = @('SchemaVersion','SnoozeHours','PromptTimeoutSeconds','LongJobThresholdSeconds',
    'DurationHistoryLimit','RequireAcPower','Operations')
$operationPolicyFields = @('Id','DisplayName','CommandFile','Effect','DueReason')
$stateFields = @('SchemaVersion','Generation','Operations')
$operationStateFields = @('Due','PromptPending','LastPromptAt','SnoozeUntil','LastAttemptAt',
    'LastSuccessAt','LastResult','DurationSecondsHistory','ConservativeDurationSeconds')

function Assert-NoDuplicateJsonFields {
    param([System.Text.Json.JsonElement] $Element, [string] $Description)
    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
        $properties = @($Element.EnumerateObject())
        $names = @($properties | ForEach-Object Name)
        if ($names.Count -ne (@($names | Select-Object -Unique)).Count) { throw "$Description contains duplicate fields" }
        foreach ($property in $properties) { Assert-NoDuplicateJsonFields $property.Value $Description }
    } elseif ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
        foreach ($item in $Element.EnumerateArray()) { Assert-NoDuplicateJsonFields $item $Description }
    }
}

function ConvertFrom-StrictJson {
    param([string] $Json, [string] $Description)
    try { $document = [System.Text.Json.JsonDocument]::Parse($Json) }
    catch { throw "$Description is unreadable or malformed" }
    try {
        Assert-NoDuplicateJsonFields $document.RootElement $Description
        $Json | ConvertFrom-Json -ErrorAction Stop
    } finally { $document.Dispose() }
}

function Assert-ExactObject {
    param($Value, [string[]] $Fields, [string] $Description)
    if ($null -eq $Value -or $Value -isnot [pscustomobject]) { throw "$Description must be a JSON object" }
    $names = @($Value.PSObject.Properties.Name)
    $missing = @($Fields | Where-Object { $_ -notin $names })
    $extra = @($names | Where-Object { $_ -notin $Fields })
    if ($missing.Count -gt 0) { throw "$Description is missing field: $($missing[0])" }
    if ($extra.Count -gt 0) { throw "$Description contains unknown field: $($extra[0])" }
}

function Assert-Integer {
    param($Value, [string] $Name, [long] $Minimum, [long] $Maximum)
    if ($Value -isnot [byte] -and $Value -isnot [sbyte] -and $Value -isnot [int16] -and
        $Value -isnot [uint16] -and $Value -isnot [int32] -and $Value -isnot [uint32] -and
        $Value -isnot [int64] -and $Value -isnot [uint64]) { throw "$Name must be a JSON integer" }
    $number = [long]$Value
    if ($number -lt $Minimum -or $number -gt $Maximum) { throw "$Name must be between $Minimum and $Maximum" }
    $number
}

function Assert-NullableTimestamp {
    param($Value, [string] $Name)
    if ($null -eq $Value) { return }
    if ($Value -is [datetime] -or $Value -is [datetimeoffset]) { return }
    if ($Value -isnot [string] -or $Value -notmatch '^\d{4}-\d{2}-\d{2}T') { throw "$Name must be null or an ISO-8601 timestamp" }
    $parsed = [datetimeoffset]::MinValue
    if (-not [datetimeoffset]::TryParse($Value, [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsed)) { throw "$Name must be null or an ISO-8601 timestamp" }
}

function Read-Policy {
    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) { throw "Long-job policy is absent: $PolicyPath" }
    $policy = ConvertFrom-StrictJson (Get-Content -LiteralPath $PolicyPath -Raw) 'Long-job policy'
    Assert-ExactObject $policy $policyFields 'Long-job policy'
    Assert-Integer $policy.SchemaVersion 'Policy.SchemaVersion' 1 1 | Out-Null
    Assert-Integer $policy.SnoozeHours 'Policy.SnoozeHours' 24 24 | Out-Null
    Assert-Integer $policy.PromptTimeoutSeconds 'Policy.PromptTimeoutSeconds' 30 3600 | Out-Null
    Assert-Integer $policy.LongJobThresholdSeconds 'Policy.LongJobThresholdSeconds' 120 120 | Out-Null
    Assert-Integer $policy.DurationHistoryLimit 'Policy.DurationHistoryLimit' 1 20 | Out-Null
    if ($policy.RequireAcPower -isnot [bool] -or -not $policy.RequireAcPower) { throw 'Policy.RequireAcPower must be true' }
    if ($policy.Operations -isnot [array] -or $policy.Operations.Count -eq 0) { throw 'Policy.Operations must be a non-empty JSON array' }
    $ids = @()
    foreach ($operation in $policy.Operations) {
        Assert-ExactObject $operation $operationPolicyFields 'Policy operation'
        if ($operation.Id -isnot [string] -or $operation.Id -notmatch '^[a-z][a-z0-9-]{1,39}$') { throw 'Policy operation Id is invalid' }
        if ($operation.DisplayName -isnot [string] -or [string]::IsNullOrWhiteSpace($operation.DisplayName)) { throw 'Policy operation DisplayName is invalid' }
        if ($operation.CommandFile -isnot [string] -or $operation.CommandFile -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*\.ps1$') { throw 'Policy operation CommandFile must be a leaf PowerShell script name' }
        foreach ($name in 'Effect','DueReason') {
            if ($operation.$name -isnot [string] -or [string]::IsNullOrWhiteSpace($operation.$name)) { throw "Policy operation $name is invalid" }
        }
        if ($operation.Id -in $ids) { throw "Policy contains duplicate operation Id: $($operation.Id)" }
        $ids += $operation.Id
    }
    $policy
}

function New-State {
    param($Policy)
    $operations = [ordered]@{}
    foreach ($operation in $Policy.Operations) {
        $operations[$operation.Id] = [pscustomobject][ordered]@{
            Due = $true; PromptPending = $false; LastPromptAt = $null; SnoozeUntil = $null
            LastAttemptAt = $null; LastSuccessAt = $null; LastResult = $null
            DurationSecondsHistory = @(); ConservativeDurationSeconds = $null
        }
    }
    [pscustomobject][ordered]@{ SchemaVersion = 1; Generation = 0; Operations = [pscustomobject]$operations }
}

function Assert-State {
    param($State, $Policy)
    Assert-ExactObject $State $stateFields 'Long-job state'
    Assert-Integer $State.SchemaVersion 'State.SchemaVersion' 1 1 | Out-Null
    Assert-Integer $State.Generation 'State.Generation' 0 ([long]::MaxValue) | Out-Null
    Assert-ExactObject $State.Operations @($Policy.Operations.Id) 'State.Operations'
    foreach ($operation in $Policy.Operations) {
        $value = $State.Operations.($operation.Id)
        Assert-ExactObject $value $operationStateFields "State operation $($operation.Id)"
        if ($value.Due -isnot [bool] -or $value.PromptPending -isnot [bool]) { throw "State operation $($operation.Id) boolean fields are invalid" }
        foreach ($name in 'LastPromptAt','SnoozeUntil','LastAttemptAt','LastSuccessAt') { Assert-NullableTimestamp $value.$name "State.$($operation.Id).$name" }
        if ($null -ne $value.LastResult -and $value.LastResult -notin @('Declined','TimedOut','Ignored','Success','Failed','Interrupted')) { throw "State operation $($operation.Id) LastResult is invalid" }
        if ($value.DurationSecondsHistory -isnot [array]) { throw "State operation $($operation.Id) duration history must be an array" }
        foreach ($duration in $value.DurationSecondsHistory) {
            if ($duration -isnot [double] -and $duration -isnot [int] -and $duration -isnot [long] -or [double]$duration -lt 0) { throw "State operation $($operation.Id) duration is invalid" }
        }
        if ($value.DurationSecondsHistory.Count -gt [int]$Policy.DurationHistoryLimit) { throw "State operation $($operation.Id) duration history is too long" }
        if ($null -ne $value.ConservativeDurationSeconds -and ([double]$value.ConservativeDurationSeconds -lt 0)) { throw "State operation $($operation.Id) conservative duration is invalid" }
    }
}

function Read-State {
    param($Policy)
    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { throw "Long-job state is absent: $StatePath" }
    $state = ConvertFrom-StrictJson (Get-Content -LiteralPath $StatePath -Raw) 'Long-job state'
    Assert-State $state $Policy
    $state
}

function Write-StateAtomic {
    param($State, $Policy)
    Assert-State $State $Policy
    $directory = Split-Path -Parent $StatePath
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = Join-Path $directory ('.{0}.{1}.tmp' -f [IO.Path]::GetFileName($StatePath), [guid]::NewGuid())
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($State | ConvertTo-Json -Depth 10 -Compress))
        $stream = [IO.FileStream]::new($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        [IO.File]::Move($temporary, $StatePath, $true)
    } finally { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
}

function Invoke-JsonAdapter {
    param([string] $Path, [string] $Description, [hashtable] $Arguments, [switch] $VisiblePrompt)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Description adapter is absent" }
    $psi = [Diagnostics.ProcessStartInfo]::new((Get-PowerShell7Path))
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = -not $VisiblePrompt
    foreach ($argument in @('-NoLogo','-NoProfile','-NonInteractive','-File',$Path)) { $psi.ArgumentList.Add($argument) }
    foreach ($entry in $Arguments.GetEnumerator()) { $psi.ArgumentList.Add("-$($entry.Key)"); $psi.ArgumentList.Add([string]$entry.Value) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $psi; $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = if ($VisiblePrompt) { '' } else { $process.StandardError.ReadToEnd() }
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "$Description adapter failed: $($stderr.Trim())" }
    $lines = @($stdout.Trim() -split "\r?\n" | Where-Object { $_ -ne '' })
    if ($lines.Count -ne 1) { throw "$Description adapter must emit exactly one JSON object" }
    ConvertFrom-StrictJson $lines[0] "$Description adapter result"
}

function Get-MonotonicSeconds {
    if ([string]::IsNullOrWhiteSpace($MonotonicClockAdapterPath)) { return [double][Diagnostics.Stopwatch]::GetTimestamp() / [Diagnostics.Stopwatch]::Frequency }
    $result = Invoke-JsonAdapter $MonotonicClockAdapterPath 'Monotonic clock' @{ Action='Read' }
    Assert-ExactObject $result @('Seconds') 'Monotonic clock adapter result'
    if ($result.Seconds -isnot [double] -and $result.Seconds -isnot [int] -and $result.Seconds -isnot [long]) { throw 'Monotonic clock adapter Seconds is invalid' }
    [double]$result.Seconds
}

function Add-DurationEvidence {
    param($OperationState, [double] $Duration, $Policy)
    $history = @($OperationState.DurationSecondsHistory) + [math]::Round($Duration, 3)
    $OperationState.DurationSecondsHistory = @($history | Select-Object -Last ([int]$Policy.DurationHistoryLimit))
    $maximum = ($OperationState.DurationSecondsHistory | Measure-Object -Maximum).Maximum
    $OperationState.ConservativeDurationSeconds = [math]::Ceiling([double]$maximum * 1.25)
}

$lockStream = $null
try {
    $policy = Read-Policy
    $lockDirectory = Split-Path -Parent $StatePath
    New-Item -ItemType Directory -Path $lockDirectory -Force | Out-Null
    try {
        $lockStream = [IO.FileStream]::new("$StatePath.lock", [IO.FileMode]::OpenOrCreate,
            [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    } catch [IO.IOException] {
        [ordered]@{Status='OverlapRefused';OfferedOperations=0;CommandRan=$false} | ConvertTo-Json -Compress
        exit 0
    }

    if ($Action -eq 'Initialize') {
        if (Test-Path -LiteralPath $StatePath) { throw "Long-job state already exists: $StatePath" }
        $state = New-State $policy; Write-StateAtomic $state $policy
        [ordered]@{Status='Initialized';Generation=0} | ConvertTo-Json -Compress
        exit 0
    }
    $state = Read-State $policy
    if ($Action -eq 'ReadStatus') {
        [ordered]@{Status='Ready';State=$state} | ConvertTo-Json -Depth 10 -Compress
        exit 0
    }
    if ([string]::IsNullOrWhiteSpace($OperationId)) { throw 'Offer requires OperationId' }
    $operation = @($policy.Operations | Where-Object Id -eq $OperationId)
    if ($operation.Count -ne 1) { throw "OperationId is not present in the reviewed policy: $OperationId" }
    $operation = $operation[0]
    $operationState = $state.Operations.$OperationId
    if (-not $operationState.Due) {
        [ordered]@{Status='NotDue';OfferedOperations=0;CommandRan=$false} | ConvertTo-Json -Compress
        exit 0
    }
    if ($operationState.PromptPending) {
        $operationState.PromptPending = $false
        $operationState.LastResult = 'Ignored'
        $operationState.SnoozeUntil = $Now.ToUniversalTime().AddHours([int]$policy.SnoozeHours).ToString('o')
        $state.Generation = [long]$state.Generation + 1; Write-StateAtomic $state $policy
        [ordered]@{Status='RecoveredIgnoredPrompt';OfferedOperations=0;CommandRan=$false;Due=$true} | ConvertTo-Json -Compress
        exit 0
    }
    if ($null -ne $operationState.SnoozeUntil -and [datetimeoffset]$Now -lt [datetimeoffset]$operationState.SnoozeUntil) {
        [ordered]@{Status='Snoozed';OfferedOperations=0;CommandRan=$false;SnoozeUntil=$operationState.SnoozeUntil} | ConvertTo-Json -Compress
        exit 0
    }

    $interactive = Invoke-JsonAdapter $InteractiveAdapterPath 'Interactive session' @{Action='Probe'}
    Assert-ExactObject $interactive @('Interactive') 'Interactive session adapter result'
    if ($interactive.Interactive -isnot [bool]) { throw 'Interactive session adapter result is invalid' }
    if (-not $interactive.Interactive) {
        [ordered]@{Status='DeferredNoInteractiveSession';OfferedOperations=0;CommandRan=$false;Due=$true} | ConvertTo-Json -Compress
        exit 0
    }
    $power = Invoke-JsonAdapter $PowerAdapterPath 'Power' @{Action='Probe'}
    Assert-ExactObject $power @('OnAc') 'Power adapter result'
    if ($power.OnAc -isnot [bool]) { throw 'Power adapter result is invalid' }
    if ($policy.RequireAcPower -and -not $power.OnAc) {
        [ordered]@{Status='DeferredPower';OfferedOperations=0;CommandRan=$false;Due=$true} | ConvertTo-Json -Compress
        exit 0
    }

    $operationState.PromptPending = $true
    $operationState.LastPromptAt = $Now.ToUniversalTime().ToString('o')
    $state.Generation = [long]$state.Generation + 1; Write-StateAtomic $state $policy
    $promptPath = Join-Path (Split-Path -Parent $StatePath) ('.consent-prompt.{0}.json' -f [guid]::NewGuid())
    try {
        [ordered]@{
            SchemaVersion=1;OperationId=$operation.Id;DisplayName=$operation.DisplayName;Effect=$operation.Effect
            DueReason=$operation.DueReason;Power='AC';LastSuccessfulCompletion=$operationState.LastSuccessAt
            PreviousResult=$operationState.LastResult;PreviousDurationSeconds=(@($operationState.DurationSecondsHistory) | Select-Object -Last 1)
            ConservativeDurationSeconds=$operationState.ConservativeDurationSeconds;Question='Run it now?';Choices=@('Yes','No')
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $promptPath -Encoding UTF8
        $prompt = Invoke-JsonAdapter $PromptAdapterPath 'Consent prompt' @{PromptPath=$promptPath;TimeoutSeconds=$policy.PromptTimeoutSeconds} -VisiblePrompt
    } finally { Remove-Item -LiteralPath $promptPath -Force -ErrorAction SilentlyContinue }
    Assert-ExactObject $prompt @('Decision') 'Consent prompt adapter result'
    if ($prompt.Decision -notin @('Yes','No','TimedOut','Ignored')) { throw 'Consent prompt decision is invalid' }
    $operationState.PromptPending = $false
    if ($prompt.Decision -ne 'Yes') {
        # MUTATION-SEAM: No, timeout, and ignored prompts retain due work and start the approved snooze.
        $operationState.Due = $true
        $operationState.LastResult = if ($prompt.Decision -eq 'No') { 'Declined' } else { [string]$prompt.Decision }
        $operationState.SnoozeUntil = $Now.ToUniversalTime().AddHours([int]$policy.SnoozeHours).ToString('o')
        $state.Generation = [long]$state.Generation + 1; Write-StateAtomic $state $policy
        [ordered]@{Status=$operationState.LastResult;OfferedOperations=1;CommandRan=$false;Due=$true;SnoozeUntil=$operationState.SnoozeUntil} | ConvertTo-Json -Compress
        exit 0
    }

    # MUTATION-SEAM: command dispatch exists only after explicit current consent.
    $commandPath = Join-Path (Split-Path -Parent $PolicyPath) $operation.CommandFile
    if (-not (Test-Path -LiteralPath $commandPath -PathType Leaf)) { throw "Reviewed operation command is absent: $commandPath" }
    $sleepToken = $null
    $commandResult = 'Failed'
    $duration = 0.0
    try {
        # MUTATION-SEAM: idle-sleep inhibition is requested only after approval and is explicitly limited in scope.
        $acquired = Invoke-JsonAdapter $SleepInhibitionAdapterPath 'Idle-sleep inhibition' @{Action='Acquire';Scope='IdleSleepOnly'}
        Assert-ExactObject $acquired @('Token') 'Idle-sleep inhibition acquire result'
        if ($acquired.Token -isnot [string] -or [string]::IsNullOrWhiteSpace($acquired.Token)) { throw 'Idle-sleep inhibition token is invalid' }
        $sleepToken = $acquired.Token
        $started = Get-MonotonicSeconds
        $result = Invoke-JsonAdapter $commandPath 'Reviewed operation command' @{OperationId=$operation.Id}
        $finished = Get-MonotonicSeconds
        $duration = $finished - $started
        if ($duration -lt 0) { throw 'Monotonic duration cannot be negative' }
        Assert-ExactObject $result @('Result') 'Reviewed operation result'
        if ($result.Result -notin @('Success','Failed','Interrupted')) { throw 'Reviewed operation result is invalid' }
        $commandResult = [string]$result.Result
    } finally {
        # MUTATION-SEAM: every acquired idle-sleep token is released after success, failure, or interruption.
        if ($null -ne $sleepToken) {
            $released = Invoke-JsonAdapter $SleepInhibitionAdapterPath 'Idle-sleep release' @{Action='Release';Scope='IdleSleepOnly';Token=$sleepToken}
            Assert-ExactObject $released @('Released') 'Idle-sleep release result'
            if ($released.Released -isnot [bool] -or -not $released.Released) { throw 'Idle-sleep inhibition was not released' }
        }
    }
    $operationState.LastAttemptAt = $Now.ToUniversalTime().ToString('o')
    $operationState.LastResult = $commandResult
    $operationState.SnoozeUntil = $null
    Add-DurationEvidence $operationState $duration $policy
    if ($commandResult -eq 'Success') {
        $operationState.Due = $false
        $operationState.LastSuccessAt = $operationState.LastAttemptAt
    } else {
        # MUTATION-SEAM: failed or interrupted work remains due.
        $operationState.Due = $true
    }
    $state.Generation = [long]$state.Generation + 1; Write-StateAtomic $state $policy
    [ordered]@{
        Status=$commandResult;OfferedOperations=1;CommandRan=$true;OperationId=$operation.Id;Due=$operationState.Due
        MeasuredDurationSeconds=$duration;ConservativeDurationSeconds=$operationState.ConservativeDurationSeconds
        InhibitionScope='IdleSleepOnly';State=$state
    } | ConvertTo-Json -Depth 10 -Compress
}
catch { Write-Error $_.Exception.Message; exit 1 }
finally { if ($null -ne $lockStream) { $lockStream.Dispose() } }
