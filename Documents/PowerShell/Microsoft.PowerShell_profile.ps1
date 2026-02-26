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

# Custom tools
Add-PathOnce "$env:USERPROFILE\tools"

# Python: use uv/uvx instead of pip
Write-Host "uv: run, init, add, pip install | uvx <tool>" -ForegroundColor Cyan

# API Keys Manager
Add-PathOnce "$env:USERPROFILE\tools\api-keys\bin"
& {
    $s = "$env:USERPROFILE\tools\api-keys\bin\ak.ps1"
    if (Test-Path $s) { . $s }
}

# Android Studio / SDK
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio1\jbr"
Add-PathOnce "$env:ANDROID_HOME\platform-tools"
Add-PathOnce "$env:ANDROID_HOME\cmdline-tools\latest\bin"
Add-PathOnce "$env:ANDROID_HOME\emulator"

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
Invoke-CachedInit 'uv-completion'  { uv generate-shell-completion powershell }
Invoke-CachedInit 'uvx-completion' { uvx --generate-shell-completion powershell }

# Start in temp dir
Set-Location $env:TEMP
