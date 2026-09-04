# Debian bootstrap

`debian-bootstrap-safe.sh` rebuilds the declared WSL workspace without relying on tools, credentials, or shell state inherited from an older installation. It is repository-only code: chezmoi does not render it into `~/scripts`.

The script must run as the target Linux user, not root. It uses `sudo` only for Debian packages and root-owned backup components. User tools, repositories, chezmoi state, and verification run as that user with an owned `HOME` and `/run/user/<uid>`.

## Reproducible inputs

`bootstrap-versions.env` pins the exact x86-64 versions, URLs, and SHA-256 hashes of chezmoi, fnm, Node.js, McFly, and Pi. Downloads enter `~/.cache/dotfiles-bootstrap` only after hash verification and are moved into place atomically.

Normal mode downloads a missing or invalid cached artifact. Offline mode accepts verified cache hits only:

```bash
BOOTSTRAP_OFFLINE=1 ./debian-bootstrap-safe.sh
```

Updating a tool requires updating its version, URL, filename, and hash together and then passing the clean-room test. System packages come from the Debian sources configured on the target; the bootstrap does not silently rewrite those sources.

## Repository selection

`workspace-repos.tsv` is the executable inventory. Each row assigns one explicit public repository to a group, destination, and profile. Initial clones use HTTPS and therefore do not require SSH keys. Existing Git checkouts are preserved.

- `foundation`: dotfiles, `ak`, agent skills, and maintained tools
- `active`: actively maintained first-party projects
- `references`: deliberate upstream or fork checkouts
- `optional`: machine- or task-specific repositories

`BOOTSTRAP_MODE=core` selects `foundation`. `BOOTSTRAP_MODE=full` selects all declared groups for the selected profile; it does **not** mean every GitHub repository. The script creates repository parent directories, never a manifest-owned destination such as `~/tools`.

## Build a retained WSL distribution

Do not paste a multi-step root setup or clone an existing VHDX. From PowerShell 7 in this repository, preview the complete retained build:

```powershell
$Rootfs = Join-Path $env:LOCALAPPDATA 'ultra-minimal-wsl\cache\debian\13.5-store-1.26.0.0\debian-13.5-amd64-wsl-rootfs.tar.gz'

./scripts/bootstrap/New-BootstrappedDebianWsl.ps1 `
  -Distribution Debian3 `
  -InstallPath C:\WSL\Debian3 `
  -RootfsPath $Rootfs `
  -ExpectedRootfsSha256 5ec7dc68216e75d1d4d4761474e99d8461a98d316537110314b137122a879e0f
```

After checking the plan, repeat with `-Execute`. The builder owns the pristine import, root and user setup, bootstrap, interactive verification, failure cleanup, and final stop. It retains a successful distribution and never copies secrets or enables host-wide WSL integration.

If a prior manual command imported the exact distribution at the exact install path but did not complete setup, add `-ResumeExisting`. Preview verifies the registry path first. A resumed distribution is never unregistered automatically if setup fails; this avoids deleting an adopted VHDX.

## Run inside an existing Debian installation

From the authoritative chezmoi source checkout:

```bash
cd ~/.local/share/chezmoi/scripts/bootstrap
BOOTSTRAP_MODE=core BOOTSTRAP_PROFILE=dev ./debian-bootstrap-safe.sh
```

Inspect behavior without system, network, or filesystem changes:

```bash
BOOTSTRAP_DRY_RUN=1 SKIP_SYSTEM_PACKAGES=1 ./debian-bootstrap-safe.sh
```

Apply the Linux home state after reviewing `chezmoi diff`:

```bash
APPLY_CHEZMOI=1 ./debian-bootstrap-safe.sh
```

Host-wide WSL integration is intentionally separate. It enables Windows executable interop and can modify Windows `.wslconfig` and Linux `/etc/wsl.conf`. Opt in only when that is the intended machine policy:

```bash
APPLY_CHEZMOI=1 DOTFILES_APPLY_WSL_INTEGRATION=1 ./debian-bootstrap-safe.sh
```

Without that variable, ordinary chezmoi application does not render or run the integration script.

Successful runs emit a marker for each tool and repository and write `~/.local/state/dotfiles-bootstrap/installed-manifest.json`. The manifest records exact installed versions and commits and explicitly records that secrets were not copied.

## Tests

Fast, side-effect-free clean-home regression test:

```bash
./scripts/bootstrap/test-bootstrap.sh
```

A full clean-room test imports an explicitly hash-bound Debian rootfs as a disposable physical-host WSL distribution, runs the bootstrap, checks an interactive login, repeats it offline, and unregisters it in `finally`. Preview is the default; `-Execute` is required because WSL registration affects the physical host:

```powershell
./scripts/bootstrap/Test-PristineDebianBootstrap.ps1 `
  -RootfsPath C:\path\to\debian-rootfs.tar.gz `
  -ExpectedRootfsSha256 <64-hex-hash> `
  -InstallPath C:\WSL\Dotfiles-Bootstrap-Test `
  -Execute
```

Use only a new disposable install path and a distribution name beginning `Dotfiles-Bootstrap-Test-`.

## AK/GnuPG secrets are a separate migration

The default bootstrap never copies GPG private keys, encrypted AK service files, SSH keys, credentials, or history. If an existing WSL distribution already contains the AK vault, preview the separately guarded migration from PowerShell 7.4+:

```powershell
./scripts/bootstrap/Copy-WslAkSecrets.ps1 `
  -SourceDistribution Debian-Recovered -SourceUser jack `
  -TargetDistribution Debian2 -TargetUser jack
```

After checking the names, repeat with `-Execute`. The operation:

- streams the complete static GnuPG state plus only `~/.config/ak`, `~/git/ak/secrets`, and `~/git/ak/.gpg-key-id`;
- rejects symlinks and unexpected archive members;
- writes no transfer archive to Windows;
- excludes SSH keys, history, plaintext secret values, and GnuPG sockets;
- backs up existing target state under `~/.local/state/dotfiles-secret-migrations/`;
- restores that backup if target validation fails;
- enforces restrictive permissions and verifies that a secret key and encrypted AK files exist.

The target's copied `vault.conf` route is rewritten to the target distribution, while the Windows route remains unchanged. The migration deliberately does not request or transport the passphrase. Complete a real decryption check interactively in the target, for example:

```bash
ak get brave >/dev/null && echo 'AK decryption verified'
```

Only after that succeeds, preview and then explicitly activate the Windows wrapper route:

```powershell
./scripts/bootstrap/Set-WindowsAkRoute.ps1 -TargetDistribution Debian2
./scripts/bootstrap/Set-WindowsAkRoute.ps1 -TargetDistribution Debian2 -Execute
```

The route update is atomic and preserves the prior configuration beside `vault.conf`. Do not paste the passphrase into a command, transcript, or chat. Keep the source distribution intact until decryption and Windows-wrapper listing both pass and the target has been backed up.

The legacy one-pass bootstrap remains historical evidence under `docs/archive/bootstrap/`; it is not an operational fallback.
