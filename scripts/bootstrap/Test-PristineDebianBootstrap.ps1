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
$rootfs = (Resolve-Path -LiteralPath $RootfsPath).Path
$actualHash = (Get-FileHash -LiteralPath $rootfs -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $ExpectedRootfsSha256.ToLowerInvariant()) { throw 'Rootfs SHA-256 mismatch.' }
$fullInstallPath = [IO.Path]::GetFullPath($InstallPath)
if (Test-Path -LiteralPath $fullInstallPath) { throw "Disposable install path already exists: $fullInstallPath" }

Write-Output "Pristine Debian bootstrap test: $Distribution"
Write-Output "  rootfs: $rootfs ($actualHash)"
Write-Output "  disposable install path: $fullInstallPath"
Write-Output '  phases: fresh import, first online bootstrap, interactive verification, offline idempotent rerun, unregister and delete'
if (-not $Execute) { Write-Output 'Preview only. Re-run with -Execute to create the disposable WSL registration.'; return }

$registeredNames = @(& wsl.exe --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect existing WSL registrations.' }
if ($registeredNames -contains $Distribution) { throw "Disposable distribution name is already registered: $Distribution" }
$importAttempted = $false
try {
    New-Item -ItemType Directory -Path $fullInstallPath -ErrorAction Stop | Out-Null
    $importAttempted = $true
    & wsl.exe --import $Distribution $fullInstallPath $rootfs --version 2
    if ($LASTEXITCODE -ne 0) { throw 'WSL import failed.' }

    $bootstrapWindows = Join-Path $PSScriptRoot 'debian-bootstrap-safe.sh'
    $bootstrapLinux = (& wsl.exe --distribution $Distribution --exec wslpath -a $bootstrapWindows | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $bootstrapLinux.StartsWith('/')) { throw 'Could not map bootstrap path into the test distribution.' }

    & wsl.exe --distribution $Distribution --user root --exec bash -c @'
set -euo pipefail
user=$1
if ! id "$user" >/dev/null 2>&1; then useradd --create-home --shell /bin/bash "$user"; fi
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo
printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$user" >"/etc/sudoers.d/90-$user"
chmod 0440 "/etc/sudoers.d/90-$user"
'@ bootstrap-test $User
    if ($LASTEXITCODE -ne 0) { throw 'Target-user preparation failed.' }

    & wsl.exe --distribution $Distribution --user $User --exec env BOOTSTRAP_MODE=core BOOTSTRAP_PROFILE=dev APPLY_CHEZMOI=1 DOTFILES_APPLY_WSL_INTEGRATION=0 bash $bootstrapLinux
    if ($LASTEXITCODE -ne 0) { throw 'First bootstrap run failed.' }
    & wsl.exe --distribution $Distribution --user $User --exec bash -lic 'set -e; command -v chezmoi; command -v node; command -v npm; command -v pi; command -v mcfly; pi list | grep -F "$HOME/git/agent-skills"; test -r "$HOME/.local/state/dotfiles-bootstrap/installed-manifest.json"'
    if ($LASTEXITCODE -ne 0) { throw 'Interactive acceptance verification failed.' }
    & wsl.exe --distribution $Distribution --user $User --exec env BOOTSTRAP_MODE=core BOOTSTRAP_PROFILE=dev APPLY_CHEZMOI=1 DOTFILES_APPLY_WSL_INTEGRATION=0 BOOTSTRAP_OFFLINE=1 SKIP_SYSTEM_PACKAGES=1 bash $bootstrapLinux
    if ($LASTEXITCODE -ne 0) { throw 'Offline idempotent bootstrap rerun failed.' }
    Write-Output 'Pristine Debian bootstrap test passed.'
}
finally {
    if ($importAttempted) {
        & wsl.exe --unregister $Distribution
        if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to unregister disposable distribution $Distribution; install-path deletion will not proceed." }
    }
    if (($LASTEXITCODE -eq 0 -or -not $importAttempted) -and (Test-Path -LiteralPath $fullInstallPath)) {
        Remove-Item -LiteralPath $fullInstallPath -Recurse -Force
    }
}
