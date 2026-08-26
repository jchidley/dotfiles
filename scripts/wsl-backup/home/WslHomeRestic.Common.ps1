#requires -Version 7.0
function Assert-PowerShell7 {
    if ($PSVersionTable.PSEdition -ne 'Core') {
        throw 'PowerShell 7 (pwsh.exe) is required; Windows PowerShell 5.1 is unsupported.'
    }
}

function Assert-WslDistroName {
    param([Parameter(Mandatory = $true)][string] $DistroName)
    if ([string]::IsNullOrWhiteSpace($DistroName) -or $DistroName -match '[\r\n"]') {
        throw 'Invalid WSL distro name'
    }
}

function Get-PowerShell7Path {
    $command = Get-Command pwsh.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1
    $command.Source
}

function Get-WslHomeTaskSpecifications {
    param([datetime] $Now = (Get-Date))
    @(
        [pscustomobject]@{Name='Backup';Command='backup';Kind='RepeatedMinutes';Value=15;Start=$Now.AddMinutes(1)},
        [pscustomobject]@{Name='Retention';Command='retention';Kind='Daily';Value='03:30';Start=$null},
        [pscustomobject]@{Name='Prune';Command='prune';Kind='Weekly';Value='Sunday@04:00';Start=$null},
        [pscustomobject]@{Name='Check';Command='check';Kind='Weekly';Value='Sunday@05:00';Start=$null},
        [pscustomobject]@{Name='Read Data Check';Command='check-read-data';Kind='RepeatedDays';Value=30;Start=$Now.Date.AddDays(1).AddHours(5)},
        [pscustomobject]@{Name='Monitor';Command='status';Kind='RepeatedMinutes';Value=30;Start=$Now.AddMinutes(5)}
    )
}

function Get-WslHomeTaskTriggerPlan {
    param([Parameter(Mandatory = $true)] $Specification)
    switch ($Specification.Kind) {
        'RepeatedMinutes' {
            return [pscustomobject]@{Kind='Repeated';At=$Specification.Start;Unit='Minutes';Interval=[int]$Specification.Value;DurationDays=3650}
        }
        'RepeatedDays' {
            return [pscustomobject]@{Kind='Repeated';At=$Specification.Start;Unit='Days';Interval=[int]$Specification.Value;DurationDays=3650}
        }
        'Daily' {
            return [pscustomobject]@{Kind='Daily';At=[string]$Specification.Value}
        }
        'Weekly' {
            $parts = [string]$Specification.Value -split '@', 2
            if ($parts.Count -ne 2) { throw "Invalid weekly task value: $($Specification.Value)" }
            return [pscustomobject]@{Kind='Weekly';Day=$parts[0];At=$parts[1]}
        }
        default { throw "Unknown task trigger kind: $($Specification.Kind)" }
    }
}

function New-WslHomeTaskArguments {
    param(
        [Parameter(Mandatory = $true)][string] $WrapperPath,
        [Parameter(Mandatory = $true)][string] $Operation,
        [Parameter(Mandatory = $true)][string] $DistroName
    )
    Assert-WslDistroName -DistroName $DistroName
    if ($WrapperPath -match '"') { throw 'Wrapper path contains an unsupported quote character' }
    if ($Operation -notin @('backup','retention','prune','check','check-read-data','status')) {
        throw "Invalid home-backup operation: $Operation"
    }
    '-NoLogo -NoProfile -NonInteractive -File "{0}" -Operation {1} -DistroName "{2}"' -f `
        $WrapperPath, $Operation, $DistroName
}

function Test-WslHomeTaskRegistrationRequired {
    param([bool] $TaskExists, [bool] $Force)
    return (-not $TaskExists -or $Force)
}

function Test-WslHomeTaskActionMigrationRequired {
    param(
        [string] $CurrentExecute,
        [string] $CurrentArguments,
        [Parameter(Mandatory = $true)][string] $DesiredExecute,
        [Parameter(Mandatory = $true)][string] $DesiredArguments
    )
    return ($CurrentExecute -ne $DesiredExecute -or $CurrentArguments -ne $DesiredArguments)
}

function ConvertTo-WslHomeLogText {
    param([AllowEmptyString()][string] $Text)
    $Text -replace "[\r\n]+", ' '
}

function Test-WslHomeNotificationRequired {
    param(
        [Parameter(Mandatory = $true)][string] $Signature,
        [AllowNull()][string] $PreviousSignature,
        [timespan] $PreviousAge,
        [timespan] $SuppressionWindow = ([timespan]::FromHours(6))
    )
    -not ($PreviousSignature -eq $Signature -and $PreviousAge -lt $SuppressionWindow)
}

$script:WslHomeStateSchemaVersion = 1

function New-WslHomeCoordinatorState {
    param([datetime] $Now = (Get-Date))
    [pscustomobject]@{
        SchemaVersion = $script:WslHomeStateSchemaVersion
        LastCoordinatorAttempt = $null
        LastCoordinatorSuccess = $null
        LastPostResumeAttempt = $null
        LastPostResumeSuccess = $null
        ConsecutiveBackupFailures = 0
        ConsecutiveBackupDeferrals = 0
        Operations = [ordered]@{}
        ApprovedOperation = $null
        Recovery = [ordered]@{ LastAtomicOperation = $null }
    }
}

function Assert-WslHomeCoordinatorState {
    param([Parameter(Mandatory = $true)] $State)
    if ($null -eq $State.SchemaVersion -or [int]$State.SchemaVersion -ne $script:WslHomeStateSchemaVersion) {
        throw "Unsupported coordinator state schema version: $($State.SchemaVersion)"
    }
    foreach ($name in 'LastCoordinatorAttempt','LastCoordinatorSuccess','LastPostResumeAttempt','LastPostResumeSuccess',
        'ConsecutiveBackupFailures','ConsecutiveBackupDeferrals','Operations','ApprovedOperation','Recovery') {
        if (-not ($State.PSObject.Properties.Name -contains $name)) { throw "Missing coordinator state field: $name" }
    }
    return $true
}

function Read-WslHomeCoordinatorState {
    param([Parameter(Mandatory = $true)][string] $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Coordinator state is absent: $Path" }
    try { $state = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "Coordinator state is unreadable or malformed: $Path" }
    Assert-WslHomeCoordinatorState -State $state | Out-Null
    $state
}

function Write-WslHomeCoordinatorStateAtomic {
    param([Parameter(Mandatory = $true)] $State, [Parameter(Mandatory = $true)][string] $Path)
    Assert-WslHomeCoordinatorState -State $State | Out-Null
    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = Join-Path $directory ('.{0}.{1}.tmp' -f [IO.Path]::GetFileName($Path), [guid]::NewGuid())
    try {
        $State | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $temporary -Encoding UTF8 -NoNewline
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    } finally { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
}

function Test-WslHomeOperationDue {
    param([datetime] $Now, [AllowNull()][object] $LastSuccess, [timespan] $Interval,
        [AllowNull()][object] $SnoozeUntil, [AllowNull()][timespan] $AwakeElapsed)
    if ($null -ne $SnoozeUntil -and $Now -lt ([datetime]$SnoozeUntil)) { return $false }
    if ($null -ne $AwakeElapsed) { return ($null -eq $LastSuccess -or $AwakeElapsed -ge $Interval) }
    return ($null -eq $LastSuccess -or $Now -ge ([datetime]$LastSuccess).Add($Interval))
}

function Get-WslHomeDurationEstimate {
    param([AllowNull()][object[]] $Durations)
    $values = @($Durations | Where-Object { $_ -is [double] -or $_ -is [int] -or $_ -is [long] } | ForEach-Object { [double]$_ })
    if ($values.Count -eq 0) { return $null }
    [math]::Ceiling(($values | Measure-Object -Average).Average)
}

function Get-WslHomeExecutionPolicy {
    param([Parameter(Mandatory = $true)][string] $Operation, [AllowNull()][object] $DurationSeconds,
        [bool] $Interactive, [bool] $OnAc, [double] $LongJobThresholdSeconds = 120)
    $alwaysConsent = $Operation -in @('prune','check-read-data','system-export')
    $long = $Operation -eq 'system-export' -or $alwaysConsent -or $null -eq $DurationSeconds -or $DurationSeconds -gt $LongJobThresholdSeconds
    if (-not $Interactive -or ($long -and -not $OnAc)) { return 'Deferred' }
    if ($long) { return 'ConsentRequired' }
    'Automatic'
}

function Get-WslHomeOperationResultClass {
    param([Parameter(Mandatory = $true)][ValidateSet('Success','NoChange','DeferredLock','Failed','Declined','TimedOut')][string] $Result)
    switch ($Result) {
        { $_ -in @('Success','NoChange') } { 'Complete'; break }
        'DeferredLock' { 'DueDeferred'; break }
        { $_ -in @('Declined','TimedOut') } { 'DueSnoozed'; break }
        'Failed' { 'DueFailed'; break }
    }
}
