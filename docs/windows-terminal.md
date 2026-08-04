# Windows Terminal configuration

Windows Terminal owns and rewrites its live `settings.json`, so chezmoi does not render a complete replacement. Instead, `scripts/configure-windows-terminal.ps1` reads the live file, applies a small managed policy, preserves unrelated settings and profiles, validates the result, and replaces the file atomically.

## Managed policy

- Copy without formatting and copy on selection.
- Equal-width tabs with no tab-row acrylic.
- `SauceCodePro Nerd Font` at 12 pt.
- The complete `Gruvbox Dark (Hard)` color scheme.
- Windows PowerShell 5.1 is visible.
- The dynamically discovered PowerShell 7 profile is hidden.
- Registered WSL distributions in the profile table receive static profiles and their registered `shortcut.ico`.
- Stale managed profiles are hidden; profiles are not created for absent distributions.
- Default profile priority is Debian-Recovered, Debian, then Windows PowerShell.

Command Prompt, actions, keybindings, menus, themes, unrelated schemes, custom profiles, and unmanaged profile-default properties remain Windows Terminal-owned.

## Source layout

```text
scripts/configure-windows-terminal.ps1       policy, discovery, and safe mutation
run_onchange_after_50-windows-terminal.*     chezmoi invocation plus helper hash
tests/windows-terminal/                      non-live fixtures and regression test
```

The WSL profile policy is the `$wslProfileSpecs` table near the top of the helper. Add or rename a managed distro there rather than duplicating profile mutation code.

## Apply and test

From WSL:

```bash
./tests/windows-terminal/run.sh
chezmoi apply
```

The helper also supports an alternate settings file and injected distribution records for tests:

```powershell
& .\scripts\configure-windows-terminal.ps1 `
  -SettingsPath C:\Temp\terminal-settings.json `
  -Distributions @() `
  -WhatIf
```

`-WhatIf` performs discovery and transformation but does not create directories or write settings.
