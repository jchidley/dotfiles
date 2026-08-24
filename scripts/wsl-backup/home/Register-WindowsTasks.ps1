#requires -Version 7.0
[CmdletBinding()]
param(
    [switch] $Remove,
    [switch] $Force,
    [string] $DistroName = 'Debian-Recovered'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1')
Assert-PowerShell7
Assert-WslDistroName -DistroName $DistroName
$powershell = Get-PowerShell7Path
$prefix = 'WSL Home Restic - '
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$installDirectory = Join-Path $env:LOCALAPPDATA 'WSLHomeRestic'
$installedWrapper = Join-Path $installDirectory 'Invoke-WslHomeRestic.ps1'

$definitions = @(Get-WslHomeTaskSpecifications | ForEach-Object {
    $specification = $_
    $plan = Get-WslHomeTaskTriggerPlan -Specification $specification
    $trigger = switch ($plan.Kind) {
        'Repeated' {
            $interval = if ($plan.Unit -eq 'Minutes') {
                New-TimeSpan -Minutes $plan.Interval
            }
            else {
                New-TimeSpan -Days $plan.Interval
            }
            New-ScheduledTaskTrigger -Once -At $plan.At `
                -RepetitionInterval $interval `
                -RepetitionDuration (New-TimeSpan -Days $plan.DurationDays)
        }
        'Daily' { New-ScheduledTaskTrigger -Daily -At $plan.At }
        'Weekly' { New-ScheduledTaskTrigger -Weekly -DaysOfWeek $plan.Day -At $plan.At }
        default { throw "Unknown task trigger plan: $($plan.Kind)" }
    }
    [pscustomobject]@{Name=$specification.Name;Command=$specification.Command;Trigger=$trigger}
})

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
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1') `
    -Destination (Join-Path $installDirectory 'WslHomeRestic.Common.ps1') -Force

$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 6)

foreach ($definition in $definitions) {
    $taskName = $prefix + $definition.Name
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    $arguments = New-WslHomeTaskArguments -WrapperPath $installedWrapper `
        -Operation $definition.Command -DistroName $DistroName
    $action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments
    if (-not (Test-WslHomeTaskRegistrationRequired -TaskExists ($null -ne $existing) -Force $Force.IsPresent)) {
        $currentAction = @($existing.Actions)[0]
        if (Test-WslHomeTaskActionMigrationRequired -CurrentExecute $currentAction.Execute `
                -CurrentArguments $currentAction.Arguments -DesiredExecute $powershell -DesiredArguments $arguments) {
            Set-ScheduledTask -TaskName $taskName -Action $action | Out-Null
            Write-Output "Migrated $taskName to PowerShell 7"
        } else {
            Write-Output "Kept existing $taskName"
        }
        continue
    }
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $definition.Trigger `
        -Principal $principal -Settings $settings -Description "Local WSL home Restic $($definition.Command)" `
        -Force | Out-Null
    Write-Output "Registered $taskName"
}
