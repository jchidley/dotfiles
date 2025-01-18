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

# history across all sessions
# get-content (Get-PSReadlineOption).HistorySavePath | Out-Host -Paging
echo 'Shared history file: (Get-PSReadlineOption).HistorySavePath'

# profile reminder
echo "Run from `$profile: $PROFILE"

get-content ps_shell_hints

# ripgrep profile
$env:RIPGREP_CONFIG_PATH="$env:USERPROFILE/.ripgreprc"

# needs to be last, just in case you Ctrl-C to abort it
Invoke-Expression (& { (zoxide init powershell | Out-String) })
