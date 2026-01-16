# # Make sure you're running as an Administrator.
# # By default the ssh-agent service is disabled. Configure it to start automatically.
#  Get-Service ssh-agent | Set-Service -StartupType Automatic
#  Start-Service ssh-agent
# # Should be only needed once per machine and per ID file
#  if (Test-Path $env:USERPROFILE/.ssh/id_ed25519) {
#  		sudo ssh-add $env:USERPROFILE/.ssh/id_ed25519
#  }

# powershell scripts
if (-not ($env:path -match ";c:\\jackc\\tools($|;)")) {
$env:path += ";c:\tools"
}

if (-not ($env:path -match ";c:\\jackc\\tools\\posh($|;)")) {
$env:path += ";c:\tools\posh"
}

# Find and add Python Scripts to PATH
try {
    $pythonPackage = Get-AppxPackage -Name "PythonSoftwareFoundation.Python.3.11*" -ErrorAction Stop
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0\LocalCache\local-packages\Python311\Scripts",
        "$env:LOCALAPPDATA\Packages\$($pythonPackage.PackageFamilyName)\LocalCache\local-packages\Python311\Scripts",
        "$env:APPDATA\Python\Python311\Scripts"
    )
    
    $pythonPath = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if ($pythonPath -and ($env:PATH -split ";" -notcontains $pythonPath)) {
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$pythonPath", "User")
        $env:PATH = "$env:PATH;$pythonPath"
        Write-Host "Added: $pythonPath"
    }
} catch {
    Write-Host "Error: $_"
}

#prompt
function Global:prompt {"PS $env:username`@$env:COMPUTERNAME $PWD`n>"}

# history across all sessions
# get-content (Get-PSReadlineOption).HistorySavePath | Out-Host -Paging
echo 'Shared history file: (Get-PSReadlineOption).HistorySavePath'

# profile reminder
echo "Run from `$profile: $PROFILE"

echo 'get-content ~/ps_shell_hints'
echo 'wt -w last sp -V `; new-tab -p "Debian" `; split-pane -V -p "Debian"'
echo 'wt -w last new-tab -p "Debian"'

# ripgrep profile
$env:RIPGREP_CONFIG_PATH="$env:USERPROFILE/.ripgreprc"

# API Keys Manager (ak) - Windows Credential Manager
# See ~/tools/api-keys/LLM.md for full docs
#
# Quick usage:
#   ak-list              # Show all services with secret status
#   ak-get <service>     # Get secret from Credential Manager
#   ak-set <service>     # Store secret (prompts for value)
#   ak-rm <service>      # Remove secret
#   load-api-keys        # Load all keys into env vars
#
# View credentials: Control Panel > Credential Manager > Windows Credentials
# Secrets stored with "ak:" prefix
$env:PATH += ";$env:USERPROFILE\tools\api-keys\bin"

# Load ak PowerShell functions
$akScript = "$env:USERPROFILE\tools\api-keys\bin\ak.ps1"
if (Test-Path $akScript) {
    . $akScript
}

cd $env:TEMP

# needs to be last, just in case you Ctrl-C to abort it
Invoke-Expression (& { (zoxide init powershell | Out-String) })
(& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
(& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)
