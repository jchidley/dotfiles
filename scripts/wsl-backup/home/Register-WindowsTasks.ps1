[CmdletBinding()]
param(
    [switch] $Remove,
    [switch] $Force,
    [string] $DistroName = 'Debian-Recovered'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run this script with the built-in Windows PowerShell (powershell.exe), not pwsh.'
}
if ([string]::IsNullOrWhiteSpace($DistroName) -or $DistroName -match '[\r\n"]') {
    throw 'Invalid WSL distro name'
}
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$prefix = 'WSL Home Restic - '
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$installDirectory = Join-Path $env:LOCALAPPDATA 'WSLHomeRestic'
$installedWrapper = Join-Path $installDirectory 'Invoke-WslHomeRestic.ps1'

$definitions = @(
    @{
        Name = 'Backup'
        Command = 'backup'
        Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
            -RepetitionInterval (New-TimeSpan -Minutes 15) `
            -RepetitionDuration (New-TimeSpan -Days 3650)
    },
    @{
        Name = 'Retention'
        Command = 'retention'
        Trigger = New-ScheduledTaskTrigger -Daily -At '03:30'
    },
    @{
        Name = 'Prune'
        Command = 'prune'
        Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At '04:00'
    },
    @{
        Name = 'Check'
        Command = 'check'
        Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At '05:00'
    },
    @{
        Name = 'Read Data Check'
        Command = 'check-read-data'
        Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddDays(1).AddHours(5) `
            -RepetitionInterval (New-TimeSpan -Days 30) `
            -RepetitionDuration (New-TimeSpan -Days 3650)
    },
    @{
        Name = 'Monitor'
        Command = 'status'
        Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) `
            -RepetitionInterval (New-TimeSpan -Minutes 30) `
            -RepetitionDuration (New-TimeSpan -Days 3650)
    }
)

if ($Remove) {
    foreach ($definition in $definitions) {
        $taskName = $prefix + $definition.Name
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Output "Removed $taskName"
        }
    }
    return
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Invoke-WslHomeRestic.ps1') `
    -Destination $installedWrapper -Force

$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 6)

foreach ($definition in $definitions) {
    $taskName = $prefix + $definition.Name
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Output "Kept existing $taskName"
        continue
    }
    $arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -Operation {1} -DistroName "{2}"' -f `
        $installedWrapper, $definition.Command, $DistroName
    $action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $definition.Trigger `
        -Principal $principal -Settings $settings -Description "Local WSL home Restic $($definition.Command)" `
        -Force | Out-Null
    Write-Output "Registered $taskName"
}
