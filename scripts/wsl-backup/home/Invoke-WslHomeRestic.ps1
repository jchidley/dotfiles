[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('backup', 'retention', 'prune', 'check', 'check-read-data', 'status')]
    [string] $Operation,
    [string] $DistroName = 'Debian-Recovered'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run this script with the built-in Windows PowerShell (powershell.exe), not pwsh.'
}
if ([string]::IsNullOrWhiteSpace($DistroName) -or $DistroName -match '[\r\n"]') {
    throw 'Invalid WSL distro name'
}
$distro = $DistroName
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$msg = Join-Path $env:SystemRoot 'System32\msg.exe'
$stateDirectory = Join-Path $env:LOCALAPPDATA 'WSLHomeRestic'
$logPath = Join-Path $stateDirectory 'operations.log'
$failurePath = Join-Path $stateDirectory "active-failure-$Operation.txt"

New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null

function Write-StatusLog {
    param([string] $Level, [string] $Text)
    $safeText = $Text -replace "[\r\n]+", ' '
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value (
        '{0} level={1} operation={2} message={3}' -f (Get-Date).ToString('o'), $Level, $Operation, $safeText
    )
}

function Send-FailureNotification {
    param([string] $Reason)
    $signature = "$Operation|$Reason"
    $notify = $true
    if (Test-Path -LiteralPath $failurePath) {
        $previous = Get-Content -LiteralPath $failurePath -Raw -ErrorAction SilentlyContinue
        $age = (Get-Date) - (Get-Item -LiteralPath $failurePath).LastWriteTime
        if ($previous -eq $signature -and $age.TotalHours -lt 6) {
            $notify = $false
        }
    }
    Set-Content -LiteralPath $failurePath -Encoding UTF8 -NoNewline -Value $signature
    if ($notify) {
        $text = "WSL home backup problem: $Reason. See $logPath"
        & $msg $env:USERNAME '/TIME:60' $text | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-StatusLog 'warning' "Windows message notification failed with exit code $LASTEXITCODE"
        }
    }
}

try {
    & $wsl -d $distro -u root -- /usr/local/sbin/backup-wsl-home $Operation
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Linux operation returned exit code $exitCode"
    }
    Remove-Item -LiteralPath $failurePath -Force -ErrorAction SilentlyContinue
    Write-StatusLog 'info' 'completed successfully'
    exit 0
}
catch {
    $reason = $_.Exception.Message
    Write-StatusLog 'error' $reason
    Send-FailureNotification $reason
    exit 1
}
