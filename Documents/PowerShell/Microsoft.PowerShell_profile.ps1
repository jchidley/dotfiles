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
# Source of truth is Debian WSL GPG-backed ak. Windows keeps a duplicate in
# Credential Manager so PowerShell can autoload keys without touching GPG/WSL.
# Examples:
#   ak-list
#   ak-get openrouter
#   load-api-keys              # load Windows Credential Manager secrets into env
#   sync-wsl-api-keys          # update Windows duplicate from Debian ak, then load env
#   sync-wsl-api-keys deepseek # update one service from Debian ak
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

function sync-wsl-api-keys {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Service
    )

    Initialize-Ak

    $ak = "/home/jack/tools/api-keys/bin/ak"
    $wslServicesDir = "/home/jack/tools/api-keys/services"
    $windowsServicesDir = "$env:USERPROFILE\tools\api-keys\services"
    if (-not (Test-Path $windowsServicesDir)) {
        $null = New-Item -ItemType Directory -Path $windowsServicesDir -Force
    }

    if ($Service -and $Service.Count -gt 0) {
        $services = $Service
    } else {
        $services = & wsl -d Debian -- bash -lc "find /home/jack/tools/api-keys/secrets -maxdepth 1 -type f -name '*.gpg' -printf '%f\n' | sed 's/\.gpg$//' | sort"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to list Debian ak secrets"
        }
    }

    $synced = 0
    foreach ($svc in $services) {
        if (-not $svc) { continue }
        if ($svc -notmatch '^[A-Za-z0-9._-]+$') {
            Write-Warning "Skipping invalid ak service name: $svc"
            continue
        }

        $exportLine = (& wsl -d Debian -- $ak export $svc) | Select-Object -First 1
        if ($LASTEXITCODE -ne 0 -or -not $exportLine) {
            Write-Warning "Failed to export Debian ak secret: $svc"
            continue
        }
        if ($exportLine -notmatch "^export\s+([A-Za-z_][A-Za-z0-9_]*)='(.*)'$") {
            Write-Warning "Could not parse Debian ak export for: $svc"
            continue
        }

        $envVar = $matches[1]
        $value = $matches[2] -replace "'\\''", "'"
        Set-AkSecret -Service $svc -Value $value -ErrorAction Stop

        $yaml = & wsl -d Debian -- bash -lc "cat '$wslServicesDir/$svc.yaml' 2>/dev/null"
        if ($LASTEXITCODE -eq 0 -and $yaml) {
            Set-Content -Path (Join-Path $windowsServicesDir "$svc.yaml") -Value $yaml
        } else {
            Set-Content -Path (Join-Path $windowsServicesDir "$svc.yaml") -Value @(
                "name: $svc"
                "env_var: $envVar"
                "description: Synced from Debian ak"
            )
        }

        Set-Item -Path "env:$envVar" -Value $value
        Write-Host "[OK] Synced $svc -> $envVar" -ForegroundColor Green
        $synced++
    }

    if ($synced -eq 0) {
        Write-Warning "No Debian ak secrets were synced"
    }
}

# Autoload duplicated Windows Credential Manager secrets into each PowerShell session.
try {
    Initialize-Ak
    Load-ApiKeys
} catch {
    Write-Warning "API key autoload skipped: $($_.Exception.Message)"
}

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
