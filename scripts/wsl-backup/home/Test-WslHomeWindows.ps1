$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run this script with the built-in Windows PowerShell (powershell.exe), not pwsh.'
}
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1')

$tests = 0
function Assert-True {
    param([bool] $Condition, [string] $Message)
    $script:tests++
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}
function Expect-Throw {
    param([scriptblock] $Action, [string] $Pattern)
    $script:tests++
    $missing = "Expected action to throw pattern: $Pattern"
    try { & $Action; throw $missing }
    catch {
        if ($_.Exception.Message -eq $missing) { throw }
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "Unexpected error '$($_.Exception.Message)', expected '$Pattern'"
        }
    }
}

Assert-BuiltInWindowsPowerShell
Assert-WslDistroName -DistroName 'Debian Recovered'
Expect-Throw { Assert-WslDistroName -DistroName 'bad"name' } 'Invalid WSL distro name'
Expect-Throw { Assert-WslDistroName -DistroName "bad`nname" } 'Invalid WSL distro name'

$powershell = Get-BuiltInWindowsPowerShellPath
Assert-True ($powershell -eq (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')) 'built-in PowerShell path'

$now = [datetime]'2026-08-24T12:00:00'
$specs = @(Get-WslHomeTaskSpecifications -Now $now)
Assert-True ($specs.Count -eq 6) 'six task specifications'
Assert-True ((@($specs.Name | Sort-Object -Unique).Count) -eq 6) 'task names unique'
Assert-True (($specs | Where-Object Name -eq 'Backup').Value -eq 15) 'backup interval is 15 minutes'
Assert-True (($specs | Where-Object Name -eq 'Monitor').Value -eq 30) 'monitor interval is 30 minutes'
Assert-True (($specs | Where-Object Name -eq 'Retention').Value -eq '03:30') 'retention time'
Assert-True (($specs | Where-Object Name -eq 'Read Data Check').Start -eq $now.Date.AddDays(1).AddHours(5)) 'read-data first run'
Assert-True ((@($specs.Command | Sort-Object -Unique).Count) -eq 6) 'operations unique'
$backupPlan = Get-WslHomeTaskTriggerPlan -Specification ($specs | Where-Object Name -eq 'Backup')
Assert-True ($backupPlan.Kind -eq 'Repeated' -and $backupPlan.Unit -eq 'Minutes' -and $backupPlan.Interval -eq 15) 'backup trigger plan'
$readPlan = Get-WslHomeTaskTriggerPlan -Specification ($specs | Where-Object Name -eq 'Read Data Check')
Assert-True ($readPlan.Unit -eq 'Days' -and $readPlan.Interval -eq 30) 'read-data trigger plan'
$prunePlan = Get-WslHomeTaskTriggerPlan -Specification ($specs | Where-Object Name -eq 'Prune')
Assert-True ($prunePlan.Kind -eq 'Weekly' -and $prunePlan.Day -eq 'Sunday' -and $prunePlan.At -eq '04:00') 'weekly trigger plan'
Expect-Throw { Get-WslHomeTaskTriggerPlan -Specification ([pscustomobject]@{Kind='Unknown';Value=1}) } 'Unknown task trigger kind'

$arguments = New-WslHomeTaskArguments -WrapperPath 'C:\Fixture User\Invoke-WslHomeRestic.ps1' `
    -Operation 'backup' -DistroName 'Debian Recovered'
Assert-True ($arguments -match '-File "C:\\Fixture User\\Invoke-WslHomeRestic.ps1"') 'wrapper path quoted'
Assert-True ($arguments -match '-Operation backup') 'operation included'
Assert-True ($arguments -match '-DistroName "Debian Recovered"') 'distro quoted'
Expect-Throw { New-WslHomeTaskArguments -WrapperPath 'C:\wrapper.ps1' -Operation 'erase' -DistroName 'Debian' } 'Invalid home-backup operation'
Expect-Throw { New-WslHomeTaskArguments -WrapperPath 'C:\bad"path.ps1' -Operation 'backup' -DistroName 'Debian' } 'unsupported quote'
Assert-True (-not (Test-WslHomeTaskRegistrationRequired -TaskExists $true -Force $false)) 'existing task preserved'
Assert-True (Test-WslHomeTaskRegistrationRequired -TaskExists $false -Force $false) 'missing task registered'
Assert-True (Test-WslHomeTaskRegistrationRequired -TaskExists $true -Force $true) 'force rebuilds existing task'

Assert-True ((ConvertTo-WslHomeLogText -Text "one`r`ntwo") -eq 'one two') 'multiline logs normalized'
Assert-True (-not (Test-WslHomeNotificationRequired -Signature 'backup|failed' `
    -PreviousSignature 'backup|failed' -PreviousAge ([timespan]::FromHours(5)))) 'duplicate notification suppressed'
Assert-True (Test-WslHomeNotificationRequired -Signature 'backup|failed' `
    -PreviousSignature 'backup|failed' -PreviousAge ([timespan]::FromHours(6))) 'notification resumes at boundary'
Assert-True (Test-WslHomeNotificationRequired -Signature 'backup|new failure' `
    -PreviousSignature 'backup|failed' -PreviousAge ([timespan]::FromMinutes(1))) 'changed failure not suppressed'
Assert-True (Test-WslHomeNotificationRequired -Signature 'backup|failed' `
    -PreviousSignature $null -PreviousAge ([timespan]::MaxValue)) 'first failure notified'

Write-Output "WslHomeWindows tests passed: $tests assertions"
