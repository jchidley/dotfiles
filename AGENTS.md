# Machine-wide agent context

Use concise `AGENTS.md` files as the only active startup instructions. `CLAUDE.md` is deprecated; migrate unique current rules into the applicable `AGENTS.md` and remove the vendor-specific file.

## Detect the command environment

This Windows machine runs agents in both native Windows/MSYS Git Bash and WSL2.
Do not infer the shell from the host OS, prompt, current path, or agent name.
When shell identity or path ownership matters, or before crossing Windows,
MSYS, WSL, PowerShell, or SSH boundaries, run:

```bash
~/.pi/agent/skills/windows-env/detect-env
```

Load the `windows-env` skill for those boundary operations. Ordinary commands
that stay within the current shell do not require it.

## Cross-environment command rules

| Need | Required helper |
|---|---|
| Native `.exe` with Unix-looking path arguments | `windows-env/safe-exec` |
| Git Bash → WSL script | `windows-env/wsl-exec` |
| Bash → PowerShell script | `windows-env/ps-exec` |
| Bash → remote Bash script | `windows-env/ssh-exec` |

- `MSYS_NO_PATHCONV=1` disables MSYS path conversion only. It does not fix
  quote loss or control which shell expands `$variables`.
- Do not put nontrivial scripts inside `wsl.exe ... bash -c`,
  `powershell.exe -Command`, or `ssh host "..."` command strings.
- For multiline helper input, use a quoted here-document (`<<'TAG'`) so the
  source shell does not expand the script body.
- If the destination script also needs stdin, transfer a script file instead.
- After cross-boundary writes, verify destination state independently; a final
  zero status can hide an earlier nested-shell or pipeline failure.

## Path ownership

- Windows-native agent file tools: relative paths or `C:/...`.
- Git Bash/MSYS commands: `/c/...` or `C:/...`.
- WSL Linux commands: `/mnt/c/...` for Windows files; `~/...` for Linux work.
- Keep builds, clones, installs, and file watchers on WSL ext4, never `/mnt/c`.

## Other machine rules

- Use `windows-env/win-open`, not `xdg-open`.
- USB devices require Windows-side `usbipd attach` before WSL can see them.
- Use `uv run python` or `uvx`; do not invoke `python`/`python3` directly.
- Never store API keys in plaintext dotfiles; use the `ak` wrappers described
  by the `windows-env` skill.
