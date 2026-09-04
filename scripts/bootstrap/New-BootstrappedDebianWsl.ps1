#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$Distribution,

    [string]$InstallPath,

    [string]$RootfsPath,

    [ValidatePattern('^[0-9a-fA-F]{64}$')]
    [string]$ExpectedRootfsSha256 = '5ec7dc68216e75d1d4d4761474e99d8461a98d316537110314b137122a879e0f',

    [ValidatePattern('^[A-Za-z_][A-Za-z0-9_-]{0,31}$')]
    [string]$User = 'jack',

    [ValidateSet('core', 'full')]
    [string]$BootstrapMode = 'core',

    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$BootstrapProfile = 'dev',

    [switch]$ResumeExisting,

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RootfsPath)) {
    $RootfsPath = Join-Path $env:LOCALAPPDATA 'ultra-minimal-wsl\cache\debian\13.5-store-1.26.0.0\debian-13.5-amd64-wsl-rootfs.tar.gz'
}
if ([string]::IsNullOrWhiteSpace($InstallPath)) {
    $InstallPath = Join-Path 'C:\WSL' $Distribution
}
if (-not (Test-Path -LiteralPath $RootfsPath -PathType Leaf)) { throw "Rootfs not found: $RootfsPath" }
$rootfs = (Resolve-Path -LiteralPath $RootfsPath -ErrorAction Stop).Path
$install = [IO.Path]::GetFullPath($InstallPath)
$expectedHash = $ExpectedRootfsSha256.ToLowerInvariant()
$actualHash = (Get-FileHash -LiteralPath $rootfs -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) { throw "Rootfs SHA-256 mismatch: expected $expectedHash, found $actualHash" }
if ($ResumeExisting) {
    if (-not (Test-Path -LiteralPath $install -PathType Container)) { throw "Resume install path does not exist: $install" }
    $records = @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object DistributionName -eq $Distribution)
    if ($records.Count -ne 1) { throw "Could not uniquely resolve the registration for $Distribution." }
    $registeredPath = [IO.Path]::GetFullPath([string]$records[0].BasePath)
    if ($registeredPath -ne $install) { throw "Registered path mismatch: expected $install, found $registeredPath" }
}
elseif (Test-Path -LiteralPath $install) { throw "Install path already exists: $install" }

$bootstrapWindows = Join-Path $PSScriptRoot 'debian-bootstrap-safe.sh'
if (-not (Test-Path -LiteralPath $bootstrapWindows -PathType Leaf)) { throw "Bootstrap script is missing: $bootstrapWindows" }

Write-Output "Bootstrapped Debian WSL plan:"
Write-Output "  distribution: $Distribution"
Write-Output "  install path: $install"
Write-Output "  rootfs: $rootfs"
Write-Output "  rootfs SHA-256: $actualHash"
Write-Output "  default user: $User"
Write-Output "  import mode: $(if ($ResumeExisting) { 'resume exact registered path' } else { 'new pristine import' })"
Write-Output "  bootstrap: mode=$BootstrapMode profile=$BootstrapProfile, chezmoi apply enabled"
Write-Output '  host-wide WSL integration: disabled'
Write-Output '  secrets: not copied; use Copy-WslAkSecrets.ps1 only after this build passes'
if ($ResumeExisting) {
    Write-Output '  failure behavior: preserve the adopted distribution and install path for diagnosis'
}
else {
    Write-Output '  failure behavior: unregister the new distribution and remove only its new install path'
}
if (-not $Execute) {
    Write-Output 'Preview only. Re-run with -Execute to complete the retained physical-host WSL distribution.'
    return
}

function Invoke-WslCommand {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [AllowNull()][string]$InputText
    )
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Command wsl.exe -CommandType Application -ErrorAction Stop).Source
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.RedirectStandardInput = $null -ne $InputText
    $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $start.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    foreach ($argument in $Arguments) { [void]$start.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        if (-not $process.Start()) { throw 'wsl.exe did not start.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if ($null -ne $InputText) {
            $process.StandardInput.Write($InputText.Replace("`r`n", "`n").Replace("`r", "`n"))
            $process.StandardInput.Close()
        }
        $process.WaitForExit()
        [pscustomobject]@{
            ExitCode = $process.ExitCode
            Stdout = $stdoutTask.GetAwaiter().GetResult()
            Stderr = $stderrTask.GetAwaiter().GetResult()
        }
    }
    finally { $process.Dispose() }
}

function Assert-WslSuccess {
    param([Parameter(Mandatory = $true)]$Result, [Parameter(Mandatory = $true)][string]$Stage)
    if ($Result.ExitCode -ne 0) { throw "$Stage failed with exit $($Result.ExitCode): $($Result.Stderr.Trim())" }
    if (-not [string]::IsNullOrWhiteSpace($Result.Stdout)) { Write-Output $Result.Stdout.TrimEnd() }
    if (-not [string]::IsNullOrWhiteSpace($Result.Stderr)) { Write-Warning $Result.Stderr.TrimEnd() }
}

$list = Invoke-WslCommand -Arguments @('--list', '--quiet')
Assert-WslSuccess -Result $list -Stage 'WSL registration inspection'
$registered = @($list.Stdout -split "`r?`n" | ForEach-Object { $_.Trim([char]0).Trim() } | Where-Object { $_ })
if ($ResumeExisting) {
    if ($registered -notcontains $Distribution) { throw "Resume distribution is not registered: $Distribution" }
}
elif ($registered -contains $Distribution) { throw "Distribution is already registered: $Distribution" }

$newImport = $false
$completed = $false
try {
    if ($ResumeExisting) {
        Write-Output 'build-check:existing-import:adopted'
    }
    else {
        [void](New-Item -ItemType Directory -Path $install -ErrorAction Stop)
        $newImport = $true
        $import = Invoke-WslCommand -Arguments @('--import', $Distribution, $install, $rootfs, '--version', '2')
        Assert-WslSuccess -Result $import -Stage 'Pristine rootfs import'
        Write-Output 'build-check:import:passed'
    }

    $rootSetup = @(
        'set -euo pipefail'
        "user='$User'"
        'id "$user" >/dev/null 2>&1 || useradd --create-home --shell /bin/bash "$user"'
        'apt-get update'
        'DEBIAN_FRONTEND=noninteractive apt-get install -y sudo'
        'printf "%s ALL=(ALL:ALL) NOPASSWD: ALL\n" "$user" >"/etc/sudoers.d/90-$user"'
        'chmod 0440 "/etc/sudoers.d/90-$user"'
        'printf "[user]\ndefault=%s\n" "$user" >/etc/wsl.conf'
    ) -join "`n"
    $rootSetup += "`n"
    $setup = Invoke-WslCommand -Arguments @('--distribution', $Distribution, '--user', 'root', '--exec', 'bash', '-s', '--') -InputText $rootSetup
    Assert-WslSuccess -Result $setup -Stage 'Root and target-user setup'
    Write-Output 'build-check:user-setup:passed'

    $mapped = Invoke-WslCommand -Arguments @('--distribution', $Distribution, '--user', 'root', '--exec', 'wslpath', '-a', $bootstrapWindows)
    Assert-WslSuccess -Result $mapped -Stage 'Bootstrap path mapping'
    $bootstrapLinux = $mapped.Stdout.Trim()
    if (-not $bootstrapLinux.StartsWith('/')) { throw "Invalid bootstrap path returned by WSL: $bootstrapLinux" }

    $bootstrap = Invoke-WslCommand -Arguments @(
        '--distribution', $Distribution, '--user', $User, '--exec',
        'env', "BOOTSTRAP_MODE=$BootstrapMode", "BOOTSTRAP_PROFILE=$BootstrapProfile",
        'APPLY_CHEZMOI=1', 'DOTFILES_APPLY_WSL_INTEGRATION=0',
        'bash', $bootstrapLinux
    )
    Assert-WslSuccess -Result $bootstrap -Stage 'User bootstrap'
    Write-Output 'build-check:bootstrap:passed'

    $terminate = Invoke-WslCommand -Arguments @('--terminate', $Distribution)
    Assert-WslSuccess -Result $terminate -Stage 'Default-user restart'
    $defaultUser = Invoke-WslCommand -Arguments @('--distribution', $Distribution, '--exec', 'id', '-un')
    Assert-WslSuccess -Result $defaultUser -Stage 'Default-user verification'
    if ($defaultUser.Stdout.Trim() -ne $User) { throw "Default user is '$($defaultUser.Stdout.Trim())', expected '$User'." }
    Write-Output "build-check:default-user:$User"

    $verifyScript = @(
        'set -euo pipefail'
        'command -v chezmoi >/dev/null; echo build-check:chezmoi:passed'
        'command -v node >/dev/null; echo build-check:node:passed'
        'command -v npm >/dev/null; echo build-check:npm:passed'
        'command -v pi >/dev/null; echo build-check:pi:passed'
        'command -v mcfly >/dev/null; echo build-check:mcfly:passed'
        'pi list | grep -F "$HOME/git/agent-skills" >/dev/null; echo build-check:pi-package:passed'
        'test -r "$HOME/.local/state/dotfiles-bootstrap/installed-manifest.json"; echo build-check:manifest:passed'
    ) -join '; '
    $verify = Invoke-WslCommand -Arguments @('--distribution', $Distribution, '--user', $User, '--exec', 'bash', '-lic', $verifyScript)
    Assert-WslSuccess -Result $verify -Stage 'Interactive login verification'

    $finalStop = Invoke-WslCommand -Arguments @('--terminate', $Distribution)
    Assert-WslSuccess -Result $finalStop -Stage 'Final distribution stop'
    $completed = $true
    Write-Output "Bootstrapped distribution '$Distribution' is retained and stopped at $install."
}
finally {
    if (-not $completed -and $newImport) {
        Write-Warning "Build failed; unregistering incomplete distribution $Distribution."
        $cleanup = Invoke-WslCommand -Arguments @('--unregister', $Distribution)
        if ($cleanup.ExitCode -ne 0) {
            Write-Warning "Automatic unregister failed: $($cleanup.Stderr.Trim())"
        }
        elseif (Test-Path -LiteralPath $install) {
            Remove-Item -LiteralPath $install -Recurse -Force
        }
    }
}
