if (Test-Path $env:USERPROFILE/.ssh/id_ed25519) {
		ssh-add $env:USERPROFILE/.ssh/id_ed25519
}

Invoke-Expression (& { (zoxide init powershell | Out-String) })


