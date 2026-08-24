[CmdletBinding()]
param(
    [switch] $Remove,
    [switch] $Force,
    [string] $DistroName = 'Debian-Recovered'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1')
Assert-BuiltInWindowsPowerShell
Assert-WslDistroName -DistroName $DistroName
$powershell = Get-BuiltInWindowsPowerShellPath
$prefix = 'WSL Home Restic - '
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$installDirectory = Join-Path $env:LOCALAPPDATA 'WSLHomeRestic'
$installedWrapper = Join-Path $installDirectory 'Invoke-WslHomeRestic.ps1'

$definitions = @(Get-WslHomeTaskSpecifications | ForEach-Object {
    $trigger = switch ($_.Kind) {
        'RepeatedMinutes' {
            New-ScheduledTaskTrigger -Once -At $_.Start `
                -RepetitionInterval (New-TimeSpan -Minutes $_.Value) `
                -RepetitionDuration (New-TimeSpan -Days 3650)
        }
        'RepeatedDays' {
            New-ScheduledTaskTrigger -Once -At $_.Start `
                -RepetitionInterval (New-TimeSpan -Days $_.Value) `
                -RepetitionDuration (New-TimeSpan -Days 3650)
        }
        'Daily' { New-ScheduledTaskTrigger -Daily -At $_.Value }
        'Weekly' {
            $parts = $_.Value -split '@', 2
            New-ScheduledTaskTrigger -Weekly -DaysOfWeek $parts[0] -At $parts[1]
        }
        default { throw "Unknown task trigger kind: $($_.Kind)" }
    }
    [pscustomobject]@{Name=$_.Name;Command=$_.Command;Trigger=$trigger}
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
    if (-not (Test-WslHomeTaskRegistrationRequired -TaskExists ($null -ne $existing) -Force $Force.IsPresent)) {
        Write-Output "Kept existing $taskName"
        continue
    }
    $arguments = New-WslHomeTaskArguments -WrapperPath $installedWrapper `
        -Operation $definition.Command -DistroName $DistroName
    $action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $definition.Trigger `
        -Principal $principal -Settings $settings -Description "Local WSL home Restic $($definition.Command)" `
        -Force | Out-Null
    Write-Output "Registered $taskName"
}
