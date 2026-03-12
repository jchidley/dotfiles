# # SSH Agent setup (run once as Administrator):
# Get-Service ssh-agent | Set-Service -StartupType Automatic
# Start-Service ssh-agent
# ssh-add $env:USERPROFILE/.ssh/id_ed25519

# --- Cache dir for shell init scripts ---
# Regenerate all caches: Remove-Item "$env:LOCALAPPDATA\pwsh-cache\*"
$cacheDir = "$env:LOCALAPPDATA\pwsh-cache"
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

# API Keys Manager (lazy-loaded)
# Examples:
#   ak-list
#   ak-get openrouter
#   ak-get deepinfra
#   $env:OPENROUTER_API_KEY = ak-get openrouter
#   $env:DEEPINFRA_API_KEY = ak-get deepinfra
#   load-api-keys
Add-PathOnce "$env:USERPROFILE\tools\api-keys\bin"
$akScript = "$env:USERPROFILE\tools\api-keys\bin\ak.ps1"
function Initialize-Ak {
    if (Get-Alias ak-get -ErrorAction SilentlyContinue) { return }
    if (-not (Test-Path $akScript)) {
        throw "ak.ps1 not found: $akScript"
    }
    . $akScript
}
function ak-get { Initialize-Ak; Get-AkSecret @args }
function ak-set { Initialize-Ak; Set-AkSecret @args }
function ak-rm { Initialize-Ak; Remove-AkSecret @args }
function ak-list { Initialize-Ak; Get-AkList @args }
function load-api-keys { Initialize-Ak; Load-ApiKeys @args }

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
    if (-not (Test-Path $file)) {
        & $Generator | Out-String | Set-Content $file
    }
    . $file
}

Invoke-CachedInit 'starship'       { &starship init powershell --print-full-init }
Invoke-CachedInit 'zoxide'         { zoxide init powershell }
# Disabled: only needed for PowerShell tab completion, not for uv/uvx availability.
# Invoke-CachedInit 'uv-completion'  { uv generate-shell-completion powershell }
# Invoke-CachedInit 'uvx-completion' { uvx --generate-shell-completion powershell }

# pi: skip version check, always pass --no-themes
$env:PI_SKIP_VERSION_CHECK = "1"
function pi { & pi.CMD --no-themes @args }

# Start in temp dir
Set-Location $env:TEMP
