# Windows PowerShell 5.1 is deliberately unsupported by these dotfiles.
[Console]::Error.WriteLine('Windows PowerShell 5.1 is unsupported. Exit this shell and run PowerShell 7 with pwsh.exe.')
[Environment]::Exit(1)
