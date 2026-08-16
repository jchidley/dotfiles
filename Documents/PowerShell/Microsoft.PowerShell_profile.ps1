# # SSH Agent setup (run once as Administrator):
# Get-Service ssh-agent | Set-Service -StartupType Automatic
# Start-Service ssh-agent
# ssh-add $env:USERPROFILE/.ssh/id_ed25519

# --- Cache dir for shell init scripts ---
# Regenerate all caches: Remove-Item "$env:LOCALAPPDATA\pwsh-cache\*"
$cacheDir = "$env:LOCALAPPDATA\pwsh-cache\$($PSVersionTable.PSVersion.Major)"
if (-not (Test-Path $cacheDir)) { $null = New-Item -ItemType Directory -Path $cacheDir -Force }

# --- PATH helpers ---
function Add-PathOnce([string]$Dir) {
    if ($Dir -and (Test-Path $Dir) -and ($env:PATH -split ';' -notcontains $Dir)) {
        $env:PATH += ";$Dir"
    }
}

# Git Bash unix tools (needed by pi's bash tool when launched from PowerShell)
Add-PathOnce "$env:USERPROFILE\scoop\apps\git\current\usr\bin"
Add-PathOnce "$env:USERPROFILE\scoop\apps\git\current\mingw64\bin"

# Python: use uv/uvx instead of pip
Write-Host "uv: run, init, add, pip install | uvx <tool>" -ForegroundColor Cyan

# API Keys Manager
# The authoritative GPG store is in the explicitly named WSL distro configured
# by chezmoi at ~/.config/ak/vault.conf. Nothing is loaded automatically and
# there is no default-distro or Windows Credential Manager fallback.
$script:AkVaultConfig = "$env:USERPROFILE\.config\ak\vault.conf"
$script:AkVaultPath = "/home/jack/github/ak/bin/ak"
$script:AkWslDistro = $null

function Initialize-AkVault {
    if ($script:AkWslDistro) { return }
    if (-not (Test-Path $script:AkVaultConfig)) {
        throw "ak vault config not found: $script:AkVaultConfig"
    }

    $entries = @(Get-Content $script:AkVaultConfig | Where-Object { $_ -match '^wsl_distro=' })
    if ($entries.Count -ne 1) {
        throw "Expected exactly one wsl_distro entry in $script:AkVaultConfig"
    }

    $distro = ($entries[0] -replace '^wsl_distro=', '').Trim()
    if ($distro -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Invalid wsl_distro in $script:AkVaultConfig"
    }
    $script:AkWslDistro = $distro
}

function Invoke-AkVault {
    param([string[]]$AkArguments)
    Initialize-AkVault
    & wsl.exe -d $script:AkWslDistro --exec $script:AkVaultPath @AkArguments
    if ($LASTEXITCODE -ne 0) {
        throw "ak failed in WSL distro '$script:AkWslDistro' (exit $LASTEXITCODE)"
    }
}

function ak-get {
    param([Parameter(Mandatory = $true)][string]$Service)
    if ($Service -notmatch '^[A-Za-z0-9._-]+$') { throw "Invalid ak service: $Service" }
    Invoke-AkVault @('get', $Service)
}
function ak-set {
    param([Parameter(Mandatory = $true)][string]$Service)
    if ($Service -notmatch '^[A-Za-z0-9._-]+$') { throw "Invalid ak service: $Service" }
    Invoke-AkVault @('set', $Service)
}
function ak-list { Invoke-AkVault @('list') }

# Android Studio / SDK (only if installed)
if (Test-Path "$env:LOCALAPPDATA\Android\Sdk") {
    $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
    $env:JAVA_HOME = "C:\Program Files\Android\Android Studio1\jbr"
    Add-PathOnce "$env:ANDROID_HOME\platform-tools"
    Add-PathOnce "$env:ANDROID_HOME\cmdline-tools\latest\bin"
    Add-PathOnce "$env:ANDROID_HOME\emulator"
}

# Ripgrep config
$env:RIPGREP_CONFIG_PATH = "$env:USERPROFILE\.ripgreprc"

# Hints
Write-Host "get-content ~/ps_shell_hints"

# --- Shell integrations (cached) ---
# First run generates caches; regenerate: Remove-Item "$env:LOCALAPPDATA\pwsh-cache\*"

function Invoke-CachedInit([string]$Name, [scriptblock]$Generator) {
    $file = "$cacheDir\$Name.ps1"

    $needsRegen = $true
    if (Test-Path $file) {
        try {
            $item = Get-Item $file -ErrorAction Stop
            # Treat tiny files as broken/empty cache and regenerate
            $needsRegen = ($item.Length -lt 20)
        } catch {
            $needsRegen = $true
        }
    }

    if ($needsRegen) {
        $content = & $Generator | Out-String
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            Set-Content -Path $file -Value $content
        }
    }

    if (Test-Path $file) {
        . $file
    }
}

Invoke-CachedInit 'starship'       { &starship init powershell --print-full-init }
Invoke-CachedInit 'zoxide'         { zoxide init powershell }
# Disabled: only needed for PowerShell tab completion, not for uv/uvx availability.
# Invoke-CachedInit 'uv-completion'  { uv generate-shell-completion powershell }
# Invoke-CachedInit 'uvx-completion' { uvx --generate-shell-completion powershell }

# pi: skip version check, always pass --no-themes
$env:PI_SKIP_VERSION_CHECK = "1"
function pi { & pi.CMD --no-themes @args }

# Start in scratch dir
$scratchDir = "$env:USERPROFILE\tmp"
if (-not (Test-Path $scratchDir)) { $null = New-Item -ItemType Directory -Path $scratchDir -Force }
Set-Location $scratchDir
