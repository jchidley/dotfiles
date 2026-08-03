# Windows shell boundaries

This machine can run agents in Windows-native MSYS/Git Bash or in WSL2. Detect
the actual command environment before choosing path or quoting rules:

```bash
~/.pi/agent/skills/windows-env/detect-env
```

Load the `windows-env` skill for the full decision table and tested helpers.

## Defaults

| Boundary | Use | Do not use for nontrivial scripts |
|---|---|---|
| Git Bash → native `.exe` path arguments | `windows-env/safe-exec` | bare `.exe` with Unix-looking paths |
| Git Bash → WSL Bash | `windows-env/wsl-exec` | `wsl.exe ... bash -c '...'` |
| Bash → PowerShell 5.1 | `windows-env/ps-exec` | `powershell.exe -Command "...$vars..."` |
| Bash → remote Bash | `windows-env/ssh-exec` | `ssh host "...$vars..."` |

`MSYS_NO_PATHCONV=1` controls MSYS path conversion only. It does not preserve
quotes or decide which shell expands `$variables`.

For multiline scripts, use the helper's `--stdin` mode with a quoted here-doc:

```bash
~/.pi/agent/skills/windows-env/wsl-exec -d Debian --stdin <<'WSL'
set -euo pipefail
path=$HOME/repo
printf '<%s>\n' "$path"
WSL
```

The quoted delimiter is what prevents the source Bash from expanding the body.
If a transported script also needs stdin, write/transfer a script file instead.

## Paths

- Windows-native agent file tools: relative paths or `C:/...`.
- Git Bash/MSYS commands: `/c/...` or `C:/...`.
- WSL Linux commands: `/mnt/c/...` for Windows files; `~/...` for Linux work.
- Never build, clone, install, or run watchers on `/mnt/c`; keep that work on
  WSL ext4.

After any cross-boundary write, inspect the destination separately. Do not rely
only on the final exit status of a nested command or pipeline.
