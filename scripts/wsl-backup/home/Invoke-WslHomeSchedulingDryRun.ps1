#requires -Version 7.0
[CmdletBinding()]
param(
    [switch] $ReadOnly,
    [string] $StatePath = (Join-Path $env:LOCALAPPDATA 'WSLHomeRestic\coordinator-state.json'),
    [datetime] $Now = (Get-Date)
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'WslHomeRestic.Common.ps1')
Assert-PowerShell7
if (-not $ReadOnly) { throw 'Dry-run requires explicit -ReadOnly' }
$result = [ordered]@{ Mode = 'ReadOnly'; State = 'Pending'; Reason = $null; Tasks = @(); Decisions = @() }
try {
    Read-WslHomeCoordinatorState -Path $StatePath | Out-Null
    $result.State = 'Ready'
    $result.Decisions = @([pscustomobject]@{ Operation = 'Backup'; Action = 'EvaluateDuePolicy' })
} catch {
    $result.State = 'FailClosed'
    $result.Reason = $_.Exception.Message
}
try {
    $result.Tasks = @(Get-ScheduledTask -TaskName 'WSL Home Restic - *' -ErrorAction Stop |
        Select-Object -ExpandProperty TaskName)
} catch { $result.Tasks = @() }
$result | ConvertTo-Json -Depth 6
