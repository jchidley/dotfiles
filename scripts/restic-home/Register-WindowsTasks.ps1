[CmdletBinding()]
param(
    [switch] $Remove
)

$ErrorActionPreference = 'Stop'
$distro = 'Debian-Recovered'
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$prefix = 'WSL Home Restic - '
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

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

$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 6)

foreach ($definition in $definitions) {
    $taskName = $prefix + $definition.Name
    $arguments = "-d $distro -u root -- /usr/local/sbin/backup-wsl-home $($definition.Command)"
    $action = New-ScheduledTaskAction -Execute $wsl -Argument $arguments
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $definition.Trigger `
        -Principal $principal -Settings $settings -Description "Local WSL home Restic $($definition.Command)" `
        -Force | Out-Null
    Write-Output "Registered $taskName"
}
