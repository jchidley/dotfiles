# Windows Terminal configuration

Windows Terminal owns and rewrites its live `settings.json`, so chezmoi does not render a complete replacement. Instead, `scripts/configure-windows-terminal.ps1` reads the live file, applies a small managed policy, preserves unrelated settings and profiles, validates the result, and replaces the file atomically.

## Managed policy

- Copy without formatting and copy on selection.
- Equal-width tabs with no tab-row acrylic.
- `SauceCodePro Nerd Font` at 12 pt.
- The complete `Gruvbox Dark (Hard)` color scheme.
- Windows PowerShell 5.1 is marked unsupported and hidden.
- PowerShell 7 is visible and explicitly launches `pwsh.exe`.
- Registered WSL distributions in the profile table receive static profiles and their registered `shortcut.ico`.
- Managed profiles use Windows Terminal's generated GUIDs so dynamic WSL profiles are adopted rather than duplicated; superseded managed GUIDs are removed during migration.
- Stale managed profiles are hidden; profiles are not created for absent distributions.
- PowerShell 7 is always the default profile; WSL profiles remain available explicitly.

Command Prompt, actions, keybindings, menus, themes, unrelated schemes, custom profiles, and unmanaged profile-default properties remain Windows Terminal-owned.

## Source layout

```text
scripts/configure-windows-terminal.ps1       policy, discovery, and safe mutation
run_onchange_after_50-windows-terminal.*     chezmoi invocation plus helper hash
tests/windows-terminal/                      non-live fixtures and regression test
```

The WSL profile policy is the `$wslProfileSpecs` table near the top of the helper. Add or rename a managed distro there rather than duplicating profile mutation code.

## Debian4 profile and preserved Debian swirl

WSL supplies Debian4's profile through its `Microsoft.WSL` fragment. The targeted override at `AppData/Local/Microsoft/Windows Terminal/Fragments/Dotfiles/debian4.json` updates that existing profile GUID; it does not add a second profile or change Terminal/WSL defaults. It launches `wsl.exe -d Debian4 -u jack`, starts in the Linux home, and uses the preserved Debian2 red-swirl icon.

The icon, official SVG, license attribution and exact reproduction hashes live in [`../AppData/Local/dotfiles/icons/`](../AppData/Local/dotfiles/icons/README.md). Windows deployment is `%LOCALAPPDATA%\dotfiles\icons\debian-official-swirl.png`, independent of distro deletion. The PNG exactly matches Debian2's historical icon, not the stock `shortcut.ico` used by Debian3/4.

The override GUID `{4eeffcc0-18c0-5b29-b6c3-02305b49996d}` was taken from the installed Debian4 WSL fragment. If profile identity changes after a later reinstall, inspect the new WSL fragment before updating the override; do not guess a GUID. See [Terminal fragment documentation](https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions).

These Windows-only files can be deployed independently of the broad settings-policy helper. On 5 September 2026 they were copied from canonical dotfiles to their matching Windows locations and hash-verified. A matching explicit Debian4 override was also added to live `settings.json`, using the same GUID as the WSL-generated profile. No duplicate Debian4 profile or default-profile change was introduced.

### Debian2 and Debian3 Terminal removal

The owner explicitly requested **removal, not hiding**. The stale Debian2 entry was removed from live `settings.json`, and the WSL-generated Debian3 fragment was removed from `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\Microsoft.WSL`. No Debian2/Debian3 hide overrides remain in the dotfiles fragment. This Terminal action did **not** unregister Debian3, delete a VHDX, stop services or alter backup state. Debian3 was separately unregistered later; Debian2 was already unregistered.

The original settings and removed fragment were backed up under `%LOCALAPPDATA%\dotfiles\terminal-backups\remove-debian2-debian3-20260905-105411`. A first settings replacement failed before modifying the live settings; the corrected atomic replacement succeeded with a nonempty backup path. Final inspection verified no named Debian2/Debian3 profiles in live settings or installed fragments, one visible Debian4 settings entry with the expected command/icon, source/deployed fragment hash equality, exact historical icon hash, and unchanged Terminal default profile. This verifies stored configuration; the Terminal menu was not visually inspected.

WSL owns its generated fragments; while Debian3 remained registered it could recreate that entry on a registration refresh. Debian3 is now unregistered, so the warning is historical unless that name is registered again. Removing a Terminal entry is not itself a WSL registration policy. Terminal may need restarting to reload profiles/fragments; do not terminate existing user sessions automatically.

## Apply and test

PowerShell 7 (`pwsh.exe`) is required. The helper has a `#requires -Version 7.0` guard and refuses Windows PowerShell 5.1.

From WSL:

```bash
bash tests/windows-terminal/run.sh
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
