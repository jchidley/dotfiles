if (Test-Path $env:USERPROFILE/.ssh/id_ed25519) {
		ssh-add $env:USERPROFILE/.ssh/id_ed25519
}

# powershell scripts
$env:path += ";c:\tools\posh"

# ripgrep profile
$env:RIPGREP_CONFIG_PATH="$env:USERPROFILE/.ripgreprc"

# needs to be last, just in case you Ctrl-C to abort it
Invoke-Expression (& { (zoxide init powershell | Out-String) })
