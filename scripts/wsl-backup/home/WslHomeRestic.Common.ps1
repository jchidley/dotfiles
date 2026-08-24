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
