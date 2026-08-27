#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Initialize','Run','ReadStatus')][string] $Action,
    [Parameter(Mandatory = $true)][string] $PolicyPath,
    [Parameter(Mandatory = $true)][string] $StatePath,
    [ValidateSet('Resume','Login','Unlock','Periodic')][string] $Opportunity = 'Periodic',
    [long] $AwakeMinute = 0,
    [string] $BackupCommandPath,
    [datetime] $Now = (Get-Date),
    [string] $DiagnosticPath,
    [ValidateSet('None','Pending:BeforeTempWrite','Pending:AfterTempWrite','Pending:AfterFlush',
        'Pending:BeforeReplace','Pending:AfterReplace','Recovery:BeforeReplace','Final:BeforeReplace',
        'Final:AfterReplace','AfterBackup')][string] $FaultPoint = 'None'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1')
Assert-PowerShell7
if ($AwakeMinute -lt 0) { throw 'AwakeMinute must be a nonnegative integer' }
if ([string]::IsNullOrWhiteSpace($DiagnosticPath)) { $DiagnosticPath = "$StatePath.diagnostic.json" }

$policyFields = @('SchemaVersion','PeriodicIntervalMinutes','FailureWarningThreshold',
    'DeferralWarningThreshold','NotificationSuppressionHours')
$stateFields = @('SchemaVersion','Generation','PolicySha256','LastCoordinatorAttempt',
    'LastCoordinatorSuccess','LastPostResumeAttempt','LastPostResumeSuccess','LastAttemptAwakeMinute',
    'ConsecutiveBackupFailures','ConsecutiveBackupDeferrals','PendingAttempt','NotificationEpisode',
    'Operations','ApprovedOperation','Recovery')

function Assert-NoDuplicateJsonFields {
    param([System.Text.Json.JsonElement] $Element, [string] $Description)
    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
        $properties = @($Element.EnumerateObject())
        $names = @($properties | ForEach-Object Name)
        if ($names.Count -ne (@($names | Select-Object -Unique)).Count) {
            throw "$Description contains duplicate fields"
        }
        foreach ($property in $properties) { Assert-NoDuplicateJsonFields $property.Value $Description }
    } elseif ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
        foreach ($item in $Element.EnumerateArray()) { Assert-NoDuplicateJsonFields $item $Description }
    }
}

function Get-ExactJsonObject {
    param([Parameter(Mandatory = $true)][string] $Json, [Parameter(Mandatory = $true)][string[]] $Fields,
        [Parameter(Mandatory = $true)][string] $Description)
    try { $document = [System.Text.Json.JsonDocument]::Parse($Json) }
    catch { throw "$Description is unreadable or malformed" }
    try {
        if ($document.RootElement.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
            throw "$Description must be a JSON object"
        }
        Assert-NoDuplicateJsonFields $document.RootElement $Description
        $names = @($document.RootElement.EnumerateObject() | ForEach-Object Name)
        $missing = @($Fields | Where-Object { $_ -notin $names })
        $extra = @($names | Where-Object { $_ -notin $Fields })
        if ($missing.Count -gt 0) { throw "$Description is missing field: $($missing[0])" }
        if ($extra.Count -gt 0) { throw "$Description contains unknown field: $($extra[0])" }
        $Json | ConvertFrom-Json -ErrorAction Stop
    } finally { $document.Dispose() }
}

function Assert-JsonInteger {
    param($Value, [string] $Name, [long] $Minimum, [long] $Maximum = [long]::MaxValue)
    if ($Value -isnot [byte] -and $Value -isnot [sbyte] -and $Value -isnot [int16] -and
        $Value -isnot [uint16] -and $Value -isnot [int32] -and $Value -isnot [uint32] -and
        $Value -isnot [int64] -and $Value -isnot [uint64]) {
        throw "$Name must be a JSON integer"
    }
    $number = [long]$Value
    if ($number -lt $Minimum -or $number -gt $Maximum) {
        throw "$Name must be between $Minimum and $Maximum"
    }
    $number
}

function Assert-NullableTimestamp {
    param($Value, [string] $Name)
    if ($null -eq $Value) { return }
    if ($Value -is [datetime] -or $Value -is [datetimeoffset]) { return }
    if ($Value -isnot [string]) { throw "$Name must be null or an ISO-8601 timestamp string" }
    $parsed = [datetimeoffset]::MinValue
    if (-not [datetimeoffset]::TryParse($Value, [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsed) -or $Value -notmatch '^\d{4}-\d{2}-\d{2}T') {
        throw "$Name must be null or an ISO-8601 timestamp string"
    }
}

function Read-SchedulingPolicy {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Scheduling policy is absent: $Path" }
    $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    $policy = Get-ExactJsonObject -Json $json -Fields $policyFields -Description 'Scheduling policy'
    if ((Assert-JsonInteger $policy.SchemaVersion 'Policy.SchemaVersion' 1 1) -ne 1) {
        throw 'Unsupported scheduling policy schema version'
    }
    Assert-JsonInteger $policy.PeriodicIntervalMinutes 'Policy.PeriodicIntervalMinutes' 15 15 | Out-Null
    Assert-JsonInteger $policy.FailureWarningThreshold 'Policy.FailureWarningThreshold' 2 3 | Out-Null
    Assert-JsonInteger $policy.DeferralWarningThreshold 'Policy.DeferralWarningThreshold' 2 3 | Out-Null
    Assert-JsonInteger $policy.NotificationSuppressionHours 'Policy.NotificationSuppressionHours' 6 6 | Out-Null
    [pscustomobject]@{
        Value = $policy
        Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
}

function Assert-ExactNestedObject {
    param($Value, [string[]] $Fields, [string] $Description)
    if ($null -eq $Value -or $Value -isnot [pscustomobject]) { throw "$Description must be a JSON object" }
    $names = @($Value.PSObject.Properties.Name)
    $missing = @($Fields | Where-Object { $_ -notin $names })
    $extra = @($names | Where-Object { $_ -notin $Fields })
    if ($missing.Count -gt 0) { throw "$Description is missing field: $($missing[0])" }
    if ($extra.Count -gt 0) { throw "$Description contains unknown field: $($extra[0])" }
}

function Assert-SchedulingStateObject {
    param($State, [string] $ExpectedPolicySha256)
    if ((Assert-JsonInteger $State.SchemaVersion 'State.SchemaVersion' 2 2) -ne 2) {
        throw 'Unsupported coordinator state schema version'
    }
    Assert-JsonInteger $State.Generation 'State.Generation' 0 | Out-Null
    if ($State.PolicySha256 -isnot [string] -or $State.PolicySha256 -notmatch '^[A-F0-9]{64}$') {
        throw 'State.PolicySha256 must be an uppercase SHA-256 hash'
    }
    if ($State.PolicySha256 -ne $ExpectedPolicySha256) { throw 'Coordinator state policy hash does not match the reviewed policy' }
    foreach ($name in 'LastCoordinatorAttempt','LastCoordinatorSuccess','LastPostResumeAttempt','LastPostResumeSuccess') {
        Assert-NullableTimestamp $State.$name "State.$name"
    }
    if ($null -ne $State.LastAttemptAwakeMinute) {
        Assert-JsonInteger $State.LastAttemptAwakeMinute 'State.LastAttemptAwakeMinute' 0 | Out-Null
    }
    $failures = Assert-JsonInteger $State.ConsecutiveBackupFailures 'State.ConsecutiveBackupFailures' 0
    $deferrals = Assert-JsonInteger $State.ConsecutiveBackupDeferrals 'State.ConsecutiveBackupDeferrals' 0
    if ($failures -gt 0 -and $deferrals -gt 0) { throw 'Coordinator state cannot contain simultaneous failure and deferral counters' }
    if ($null -eq $State.LastAttemptAwakeMinute -and ($failures -gt 0 -or $deferrals -gt 0)) {
        throw 'Coordinator health counters require a completed attempt'
    }
    if ($null -ne $State.PendingAttempt) {
        Assert-ExactNestedObject $State.PendingAttempt @('AttemptId','Opportunity','AwakeMinute','StartedAt','PriorGeneration') 'State.PendingAttempt'
        if ($State.PendingAttempt.AttemptId -isnot [string] -or $State.PendingAttempt.AttemptId -notmatch '^[0-9a-f-]{36}$') {
            throw 'State.PendingAttempt.AttemptId must be a GUID'
        }
        if ($State.PendingAttempt.Opportunity -notin @('Resume','Login','Unlock','Periodic')) {
            throw 'State.PendingAttempt.Opportunity is invalid'
        }
        Assert-JsonInteger $State.PendingAttempt.AwakeMinute 'State.PendingAttempt.AwakeMinute' 0 | Out-Null
        Assert-NullableTimestamp $State.PendingAttempt.StartedAt 'State.PendingAttempt.StartedAt'
        Assert-JsonInteger $State.PendingAttempt.PriorGeneration 'State.PendingAttempt.PriorGeneration' 0 | Out-Null
        if ([long]$State.PendingAttempt.PriorGeneration -ge [long]$State.Generation) {
            throw 'State.PendingAttempt generation is inconsistent'
        }
    }
    Assert-ExactNestedObject $State.NotificationEpisode @('Signature','LastNotifiedAt') 'State.NotificationEpisode'
    if ($null -ne $State.NotificationEpisode.Signature -and $State.NotificationEpisode.Signature -notin @('Backup|Failed','Backup|DeferredLock')) {
        throw 'State.NotificationEpisode.Signature is invalid'
    }
    Assert-NullableTimestamp $State.NotificationEpisode.LastNotifiedAt 'State.NotificationEpisode.LastNotifiedAt'
    if (($null -eq $State.NotificationEpisode.Signature) -ne ($null -eq $State.NotificationEpisode.LastNotifiedAt)) {
        throw 'State.NotificationEpisode fields must both be null or both be set'
    }
    if ($State.Operations -isnot [pscustomobject]) { throw 'State.Operations must be a JSON object' }
    if ($null -ne $State.ApprovedOperation -and $State.ApprovedOperation -isnot [pscustomobject]) {
        throw 'State.ApprovedOperation must be null or a JSON object'
    }
    Assert-ExactNestedObject $State.Recovery @('LastAtomicOperation','LastInterruptedAttemptId') 'State.Recovery'
    if ($null -ne $State.Recovery.LastAtomicOperation -and $State.Recovery.LastAtomicOperation -isnot [string]) {
        throw 'State.Recovery.LastAtomicOperation must be null or a string'
    }
    if ($null -ne $State.Recovery.LastInterruptedAttemptId -and
        ($State.Recovery.LastInterruptedAttemptId -isnot [string] -or $State.Recovery.LastInterruptedAttemptId -notmatch '^[0-9a-f-]{36}$')) {
        throw 'State.Recovery.LastInterruptedAttemptId must be null or a GUID'
    }
    $true
}

function ConvertTo-ValidatedState {
    param([string] $Json, [string] $ExpectedPolicySha256)
    $state = Get-ExactJsonObject -Json $Json -Fields $stateFields -Description 'Coordinator state'
    Assert-SchedulingStateObject $state $ExpectedPolicySha256 | Out-Null
    $state
}

function Read-SchedulingState {
    param([string] $Path, [string] $ExpectedPolicySha256)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Coordinator state is absent: $Path" }
    try { $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop }
    catch { throw "Coordinator state is unreadable: $Path" }
    ConvertTo-ValidatedState $json $ExpectedPolicySha256
}

function New-SchedulingState {
    param([string] $PolicySha256)
    [pscustomobject][ordered]@{
        SchemaVersion = 2
        Generation = 0
        PolicySha256 = $PolicySha256
        LastCoordinatorAttempt = $null
        LastCoordinatorSuccess = $null
        LastPostResumeAttempt = $null
        LastPostResumeSuccess = $null
        LastAttemptAwakeMinute = $null
        ConsecutiveBackupFailures = 0
        ConsecutiveBackupDeferrals = 0
        PendingAttempt = $null
        NotificationEpisode = [pscustomobject][ordered]@{ Signature = $null; LastNotifiedAt = $null }
        Operations = [pscustomobject]@{}
        ApprovedOperation = $null
        Recovery = [pscustomobject][ordered]@{ LastAtomicOperation = $null; LastInterruptedAttemptId = $null }
    }
}

function Invoke-AdapterFault {
    param([string] $Phase, [string] $Point)
    if ($FaultPoint -eq "$Phase`:$Point") {
        Stop-Process -Id $PID -Force
        Start-Sleep -Seconds 30
    }
}

function Write-SchedulingStateAtomic {
    param($State, [string] $Path, [string] $ExpectedPolicySha256, [string] $Phase)
    Assert-SchedulingStateObject $State $ExpectedPolicySha256 | Out-Null
    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = Join-Path $directory ('.{0}.{1}.tmp' -f [IO.Path]::GetFileName($Path), [guid]::NewGuid())
    $backup = Join-Path $directory ('.{0}.{1}.bak' -f [IO.Path]::GetFileName($Path), [guid]::NewGuid())
    try {
        Invoke-AdapterFault $Phase 'BeforeTempWrite'
        $json = $State | ConvertTo-Json -Depth 12 -Compress
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
        $stream = [IO.FileStream]::new($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $stream.Write($bytes, 0, $bytes.Length)
            Invoke-AdapterFault $Phase 'AfterTempWrite'
            $stream.Flush($true)
        } finally { $stream.Dispose() }
        Invoke-AdapterFault $Phase 'AfterFlush'
        ConvertTo-ValidatedState (Get-Content -LiteralPath $temporary -Raw) $ExpectedPolicySha256 | Out-Null
        Invoke-AdapterFault $Phase 'BeforeReplace'
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [IO.File]::Replace($temporary, $Path, $backup, $true)
        } else {
            [IO.File]::Move($temporary, $Path)
        }
        Invoke-AdapterFault $Phase 'AfterReplace'
    } finally {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
    }
}

function Remove-AbandonedStateTemporaries {
    param([string] $Path)
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { return }
    foreach ($extension in 'tmp','bak') {
        $pattern = '.{0}.*.{1}' -f [IO.Path]::GetFileName($Path), $extension
        Get-ChildItem -LiteralPath $directory -Filter $pattern -File -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction Stop
    }
}

function Write-StateDiagnostic {
    param([string] $Reason, [int] $SuppressionHours = 6)
    $signature = "State|$Reason"
    $notify = $true
    if (Test-Path -LiteralPath $DiagnosticPath -PathType Leaf) {
        try {
            $previous = Get-Content -LiteralPath $DiagnosticPath -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($previous.SchemaVersion -eq 1 -and $previous.Signature -eq $signature -and $null -ne $previous.LastNotifiedAt) {
                $age = [datetimeoffset]$Now - [datetimeoffset]$previous.LastNotifiedAt
                $notify = $age -ge [timespan]::FromHours($SuppressionHours)
            }
        } catch { $notify = $true }
    }
    $lastNotified = if ($notify) { $Now.ToUniversalTime().ToString('o') } else { $previous.LastNotifiedAt }
    $record = [ordered]@{
        SchemaVersion = 1
        Signature = $signature
        LastObservedAt = $Now.ToUniversalTime().ToString('o')
        LastNotifiedAt = $lastNotified
        Notify = $notify
        Reason = $Reason
    }
    $directory = Split-Path -Parent $DiagnosticPath
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = Join-Path $directory ('.{0}.{1}.tmp' -f [IO.Path]::GetFileName($DiagnosticPath), [guid]::NewGuid())
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($record | ConvertTo-Json -Compress))
        $stream = [IO.FileStream]::new($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        [IO.File]::Move($temporary, $DiagnosticPath, $true)
    } finally { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
}

function Invoke-FixedBackupCommand {
    param([string] $Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw 'Run requires an existing fixed BackupCommandPath'
    }
    $output = @(& (Get-PowerShell7Path) -NoLogo -NoProfile -NonInteractive -File $Path)
    $exitCode = $LASTEXITCODE
    if ($output.Count -ne 1) { throw 'Backup command must emit exactly one JSON result object' }
    $result = Get-ExactJsonObject -Json ([string]$output[0]) -Fields @('ResultClass') -Description 'Backup result'
    $class = [string]$result.ResultClass
    if ($exitCode -eq 0 -and $class -in @('Changed','NoChange')) { return $class }
    if ($exitCode -eq 75 -and $class -eq 'Lock') { return 'DeferredLock' }
    if ($exitCode -ne 0 -and $exitCode -ne 75 -and $class -eq 'Failed') { return 'Failed' }
    throw "Unsupported backup result contract: exit $exitCode, class $class"
}

function Get-NotificationDecision {
    param($State, [string] $Result, $Policy)
    if ($Result -in @('Changed','NoChange')) {
        # MUTATION-SEAM: successful attempts end the prior notification episode.
        $State.NotificationEpisode.Signature = $null
        $State.NotificationEpisode.LastNotifiedAt = $null
        return $false
    }
    $threshold = if ($Result -eq 'Failed') { [long]$Policy.FailureWarningThreshold } else { [long]$Policy.DeferralWarningThreshold }
    $count = if ($Result -eq 'Failed') { [long]$State.ConsecutiveBackupFailures } else { [long]$State.ConsecutiveBackupDeferrals }
    # MUTATION-SEAM: warning occurs exactly at the approved boundary.
    if ($count -lt $threshold) { return $false }
    $signature = "Backup|$Result"
    $notify = $State.NotificationEpisode.Signature -ne $signature
    if (-not $notify) {
        $previous = [datetimeoffset]$State.NotificationEpisode.LastNotifiedAt
        $notify = ([datetimeoffset]$Now - $previous) -ge [timespan]::FromHours([double]$Policy.NotificationSuppressionHours)
    }
    if ($notify) {
        $State.NotificationEpisode.Signature = $signature
        $State.NotificationEpisode.LastNotifiedAt = $Now.ToUniversalTime().ToString('o')
    }
    $notify
}

$lockStream = $null
try {
    $policyRecord = Read-SchedulingPolicy $PolicyPath
    $lockDirectory = Split-Path -Parent $StatePath
    New-Item -ItemType Directory -Path $lockDirectory -Force | Out-Null
    try {
        $lockStream = [IO.FileStream]::new("$StatePath.lock", [IO.FileMode]::OpenOrCreate,
            [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    } catch [IO.IOException] {
        [ordered]@{ Status='OverlapRefused'; Notify=$false; BackupGateSatisfied=$false } | ConvertTo-Json -Compress
        exit 0
    }

    if ($Action -eq 'Initialize') {
        if (Test-Path -LiteralPath $StatePath) { throw "Coordinator state already exists: $StatePath" }
        $state = New-SchedulingState $policyRecord.Sha256
        Write-SchedulingStateAtomic $state $StatePath $policyRecord.Sha256 'Initialize'
        [ordered]@{ Status='Initialized'; Generation=0; PolicySha256=$policyRecord.Sha256 } | ConvertTo-Json -Compress
        exit 0
    }

    $state = Read-SchedulingState $StatePath $policyRecord.Sha256
    Remove-AbandonedStateTemporaries $StatePath

    if ($Action -eq 'ReadStatus') {
        [ordered]@{ Status='Ready'; State=$state; PolicySha256=$policyRecord.Sha256 } | ConvertTo-Json -Depth 12 -Compress
        exit 0
    }

    if ($null -ne $state.PendingAttempt) {
        $interruptedId = [string]$state.PendingAttempt.AttemptId
        $state.PendingAttempt = $null
        $state.Generation = [long]$state.Generation + 1
        $state.Recovery.LastInterruptedAttemptId = $interruptedId
        $state.Recovery.LastAtomicOperation = 'RecoveredInterruptedAttempt'
        Write-SchedulingStateAtomic $state $StatePath $policyRecord.Sha256 'Recovery'
    }

    if ($null -ne $state.LastAttemptAwakeMinute -and $AwakeMinute -lt [long]$state.LastAttemptAwakeMinute) {
        throw 'AwakeMinute cannot precede the last completed attempt'
    }
    # MUTATION-SEAM: only due awake-time opportunities invoke the backup command.
    $due = $Opportunity -ne 'Periodic' -or $null -eq $state.LastAttemptAwakeMinute -or
        ($AwakeMinute - [long]$state.LastAttemptAwakeMinute -ge [long]$policyRecord.Value.PeriodicIntervalMinutes)
    if (-not $due) {
        [ordered]@{ Status='NotDue'; Generation=$state.Generation; Notify=$false; BackupGateSatisfied=$false } | ConvertTo-Json -Compress
        exit 0
    }

    $attemptId = [guid]::NewGuid().ToString()
    $state.Generation = [long]$state.Generation + 1
    $state.LastCoordinatorAttempt = $Now.ToUniversalTime().ToString('o')
    if ($Opportunity -eq 'Resume') { $state.LastPostResumeAttempt = $state.LastCoordinatorAttempt }
    $state.PendingAttempt = [pscustomobject][ordered]@{
        AttemptId = $attemptId
        Opportunity = $Opportunity
        AwakeMinute = $AwakeMinute
        StartedAt = $state.LastCoordinatorAttempt
        PriorGeneration = [long]$state.Generation - 1
    }
    $state.Recovery.LastAtomicOperation = 'BackupAttemptPending'
    Write-SchedulingStateAtomic $state $StatePath $policyRecord.Sha256 'Pending'

    $result = Invoke-FixedBackupCommand $BackupCommandPath
    if ($FaultPoint -eq 'AfterBackup') { Stop-Process -Id $PID -Force; Start-Sleep -Seconds 30 }

    $state.PendingAttempt = $null
    $state.Generation = [long]$state.Generation + 1
    $state.LastAttemptAwakeMinute = $AwakeMinute
    $backupGateSatisfied = $false
    switch ($result) {
        { $_ -in @('Changed','NoChange') } {
            # MUTATION-SEAM: success resets both consecutive counters.
            $state.ConsecutiveBackupFailures = 0
            $state.ConsecutiveBackupDeferrals = 0
            $state.LastCoordinatorSuccess = $Now.ToUniversalTime().ToString('o')
            if ($Opportunity -eq 'Resume') { $state.LastPostResumeSuccess = $state.LastCoordinatorSuccess }
            $backupGateSatisfied = $true
            break
        }
        'Failed' {
            $state.ConsecutiveBackupFailures = [long]$state.ConsecutiveBackupFailures + 1
            $state.ConsecutiveBackupDeferrals = 0
            break
        }
        'DeferredLock' {
            $state.ConsecutiveBackupDeferrals = [long]$state.ConsecutiveBackupDeferrals + 1
            $state.ConsecutiveBackupFailures = 0
            break
        }
    }
    $notify = Get-NotificationDecision $state $result $policyRecord.Value
    $state.Recovery.LastAtomicOperation = "BackupResult:$result"
    Write-SchedulingStateAtomic $state $StatePath $policyRecord.Sha256 'Final'
    [ordered]@{
        Status='Completed'; Result=$result; Generation=$state.Generation; Notify=$notify;
        BackupGateSatisfied=$backupGateSatisfied; State=$state
    } | ConvertTo-Json -Depth 12 -Compress
}
catch {
    if ($null -ne $lockStream) {
        try { Write-StateDiagnostic $_.Exception.Message ([int]$policyRecord.Value.NotificationSuppressionHours) } catch { }
    }
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    if ($null -ne $lockStream) { $lockStream.Dispose() }
}
