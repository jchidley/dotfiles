# Windows Terminal configuration

Windows Terminal owns and rewrites its live `settings.json`, so chezmoi does not render a complete replacement. Instead, `scripts/configure-windows-terminal.ps1` reads the live file, applies a small managed policy, preserves unrelated settings and profiles, validates the result, and replaces the file atomically.

## Managed policy

- Copy without formatting and copy on selection.
- Equal-width tabs with no tab-row acrylic.
- `SauceCodePro Nerd Font` at 12 pt.
- The complete `Gruvbox Dark (Hard)` color scheme.
- PowerShell 7 is the default and first visible managed profile.
- `herdr` launches the stable `current\herdr.exe` installation directly with Herdr's official logo.
- Debian4 launches login Bash with the preserved red-swirl icon.
- Command Prompt remains available with its standard icon and appears last.
- Windows PowerShell 5.1 and LFS-Builder are hidden to suppress their generated profiles.

Actions, keybindings, menus, themes, unrelated schemes, custom profiles, and unmanaged profile-default properties remain Windows Terminal-owned.

## Source layout

```text
scripts/configure-windows-terminal.ps1       profile policy and safe settings mutation
AppData/Local/Microsoft/Windows Terminal/     Debian4 generated-profile override
AppData/Local/dotfiles/icons/                 stable custom profile icons
run_onchange_after_50-windows-terminal.*      chezmoi invocation plus helper hash
tests/windows-terminal/                       non-live fixtures and regression test
```

The Herdr profile icon is the upstream `assets/logo.png` from
[`herdrdev/herdr`](https://github.com/herdrdev/herdr), retained at
`AppData/Local/dotfiles/icons/herdr-logo.png` and deployed to the matching
`%LOCALAPPDATA%` path. Its SHA-256 is
`56fc2db845c16eb521022549890fbe239659957caee1f4fc718a634d7a66cf0a`.
Herdr is licensed under Apache-2.0.

## Debian4 profile and preserved Debian swirl

WSL supplies Debian4's generated profile. The settings helper adopts that GUID as a static profile, while the matching override at `AppData/Local/Microsoft/Windows Terminal/Fragments/Dotfiles/debian4.json` keeps the generated profile consistent. Both launch `wsl.exe -d Debian4 -u jack --exec bash --login`, start in the Linux home, and use the preserved Debian2 red-swirl icon.

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
