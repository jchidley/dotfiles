[CmdletBinding()]
param(
    [string] $DistroName = 'Debian-Recovered'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run this script with the built-in Windows PowerShell (powershell.exe), not pwsh.'
}
if ([string]::IsNullOrWhiteSpace($DistroName) -or $DistroName -match '[\r\n"]') {
    throw 'Invalid WSL distro name'
}

$installRoot = Join-Path $env:LOCALAPPDATA 'WSLBackup'
$systemRoot = Join-Path $installRoot 'system'
New-Item -ItemType Directory -Path $systemRoot -Force | Out-Null

foreach ($name in @(
    'Backup-WslSystem.ps1',
    'WslSystemBackup.Common.ps1',
    'validate-wsl-system-restore'
)) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "system\$name") `
        -Destination (Join-Path $systemRoot $name) -Force
}

[pscustomobject]@{
    Distro = $DistroName
    SystemController = (Join-Path $systemRoot 'Backup-WslSystem.ps1')
} | Format-List
