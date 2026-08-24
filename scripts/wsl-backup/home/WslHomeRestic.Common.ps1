function Assert-BuiltInWindowsPowerShell {
    if ($PSVersionTable.PSEdition -ne 'Desktop') {
        throw 'Run this script with the built-in Windows PowerShell (powershell.exe), not pwsh.'
    }
}

function Assert-WslDistroName {
    param([Parameter(Mandatory = $true)][string] $DistroName)
    if ([string]::IsNullOrWhiteSpace($DistroName) -or $DistroName -match '[\r\n"]') {
        throw 'Invalid WSL distro name'
    }
}

function Get-BuiltInWindowsPowerShellPath {
    Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
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
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -Operation {1} -DistroName "{2}"' -f `
        $WrapperPath, $Operation, $DistroName
}

function Test-WslHomeTaskRegistrationRequired {
    param([bool] $TaskExists, [bool] $Force)
    return (-not $TaskExists -or $Force)
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
