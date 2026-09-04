#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$RootfsPath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{64}$')]
    [string]$ExpectedRootfsSha256,

    [ValidatePattern('^Dotfiles-Bootstrap-Test-[A-Za-z0-9._-]+$')]
    [string]$Distribution = "Dotfiles-Bootstrap-Test-$([Guid]::NewGuid().ToString('N').Substring(0, 8))",

    [Parameter(Mandatory = $true)]
    [string]$InstallPath,

    [ValidatePattern('^[A-Za-z_][A-Za-z0-9_-]{0,31}$')]
    [string]$User = 'jack',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$builder = Join-Path $PSScriptRoot 'New-BootstrappedDebianWsl.ps1'
$arguments = @{
    Distribution = $Distribution
    InstallPath = $InstallPath
    RootfsPath = $RootfsPath
    ExpectedRootfsSha256 = $ExpectedRootfsSha256
    User = $User
}
if (-not $Execute) {
    & $builder @arguments
    Write-Output 'Pristine test preview only. -Execute will additionally prove an offline idempotent rerun and remove the test distribution.'
    return
}

$built = $false
try {
    & $builder @arguments -Execute
    $built = $true
    $bootstrapLinux = "/home/$User/.local/share/chezmoi/scripts/bootstrap/debian-bootstrap-safe.sh"
    & wsl.exe --distribution $Distribution --user $User --exec env `
        BOOTSTRAP_MODE=core BOOTSTRAP_PROFILE=dev APPLY_CHEZMOI=1 `
        DOTFILES_APPLY_WSL_INTEGRATION=0 BOOTSTRAP_OFFLINE=1 SKIP_SYSTEM_PACKAGES=1 `
        bash $bootstrapLinux
    if ($LASTEXITCODE -ne 0) { throw 'Offline idempotent bootstrap rerun failed.' }
    Write-Output 'Pristine Debian bootstrap and offline idempotence test passed.'
}
finally {
    if ($built) {
        & wsl.exe --unregister $Distribution
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to unregister $Distribution; preserving its install path."
        }
        elseif (Test-Path -LiteralPath $InstallPath) {
            Remove-Item -LiteralPath $InstallPath -Recurse -Force
        }
    }
}
