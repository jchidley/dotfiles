#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$TargetDistribution,

    [string]$ConfigPath = (Join-Path $HOME '.config\ak\vault.conf'),

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$config = (Resolve-Path -LiteralPath $ConfigPath -ErrorAction Stop).Path
$text = [IO.File]::ReadAllText($config)
$routeMatches = [regex]::Matches($text, '(?m)^wsl_distro=([^\r\n]+)$')
if ($routeMatches.Count -ne 1) { throw 'The AK vault configuration must contain exactly one wsl_distro entry.' }
$current = $routeMatches[0].Groups[1].Value
Write-Output "Windows AK route: $current -> $TargetDistribution"
if (-not $Execute) {
    Write-Output 'Preview only. First verify passphrase-based decryption in the target, then re-run with -Execute.'
    return
}
if ($current -eq $TargetDistribution) { Write-Output 'Windows AK route is already correct.'; return }

$updated = [regex]::Replace($text, '(?m)^wsl_distro=[^\r\n]+$', "wsl_distro=$TargetDistribution")
$directory = Split-Path -Parent $config
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$backup = Join-Path $directory "vault.conf.before-$stamp"
if (Test-Path -LiteralPath $backup) { throw "Backup path already exists: $backup" }
$temporary = Join-Path $directory ".vault.conf.$([Guid]::NewGuid().ToString('N')).tmp"
try {
    [IO.File]::WriteAllText($temporary, $updated, [Text.UTF8Encoding]::new($false))
    [IO.File]::Replace($temporary, $config, $backup, $true)
    $check = [IO.File]::ReadAllText($config)
    if ($check -notmatch "(?m)^wsl_distro=$([regex]::Escape($TargetDistribution))$") {
        [IO.File]::Copy($backup, $config, $true)
        throw 'Route verification failed; the original configuration was restored.'
    }
    Write-Output "Windows AK route updated. Previous configuration: $backup"
}
finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
}
