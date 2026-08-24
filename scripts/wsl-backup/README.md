# WSL backup and recovery

This directory is the canonical implementation and operational entry point for backing up `Debian-Recovered`. It does not own recovery history or benchmark evidence; those live in the `jchidley/tools` WSL backup reference.

## Quick start

From the chezmoi source checkout inside WSL:

```bash
cd ~/.local/share/chezmoi
./scripts/wsl-backup/setup.sh
wsl-backup status
```

`setup.sh` is idempotent and non-destructive. It installs or updates the Linux programs and Windows system-export controller. When an existing Restic repository and password file are present, it also registers any missing Windows tasks while preserving existing schedules. Use `--force-windows-tasks` only when task definitions must be rebuilt. Setup never creates credentials, initializes a repository, deletes snapshots, or creates a whole-system export.

For a distro whose registered name is not `Debian-Recovered`:

```bash
./scripts/wsl-backup/setup.sh --distro NAME
```

## Everyday commands

```bash
# Combined status
wsl-backup status

# Home snapshots
wsl-backup home snapshots
wsl-backup home backup
wsl-backup home check

# Whole-system operations
wsl-backup system Preflight
wsl-backup system Status
wsl-backup system Export -ConfirmMaintenanceWindow
```

Whole-system export stops the source distro. It remains protected by the explicit `-ConfirmMaintenanceWindow` gate.

Restore home data only into an empty ext4 staging directory:

```bash
wsl-backup home restore latest /var/tmp/restic-home-restore
```

## Components

| Path | Responsibility |
|---|---|
| [`home/`](home/README.md) | Frequent encrypted Restic snapshots, retention, checks, staged restore, scheduler wrapper, and Windows task registration |
| [`system/`](system/README.md) | Cold complete-distro export, disposable-import validation, manifests, retention, crash recovery, and cleanup |
| `setup.sh` | One-command non-destructive installation and Windows integration |
| `wsl-backup` | Installed operator command for home and system operations |
| `Install-Windows.ps1` | Installs the system-export controller outside the distro so it remains available while the source is stopped |

## Initialization boundary

A fresh machine needs a separately escrowed Restic password and explicit repository initialization. Setup intentionally stops before this security boundary. Follow [`home/README.md`](home/README.md#initialize-explicitly), test the Bitwarden recovery value, then rerun `setup.sh` to register scheduling.

## Validation

Linux fixture test:

```bash
sudo ./scripts/wsl-backup/home/test.sh
```

Windows-only system test (does not invoke WSL or alter production tasks):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  .\scripts\wsl-backup\system\Test-WslSystemBackup.ps1
```

Static checks:

```bash
bash -n scripts/wsl-backup/setup.sh scripts/wsl-backup/wsl-backup \
  scripts/wsl-backup/home/*.sh scripts/wsl-backup/home/backup-wsl-home \
  scripts/wsl-backup/system/install.sh scripts/wsl-backup/system/validate-wsl-system-restore
shellcheck scripts/wsl-backup/setup.sh scripts/wsl-backup/wsl-backup \
  scripts/wsl-backup/home/*.sh scripts/wsl-backup/home/backup-wsl-home \
  scripts/wsl-backup/system/install.sh scripts/wsl-backup/system/validate-wsl-system-restore
```

## Documentation ownership

- This README and component READMEs: current commands and operational behaviour.
- Source code and tests: implementation truth.
- `jchidley/tools/docs/wsl-backup.md`: clean cross-repository reference, capability status, and reading path.
- `jchidley/tools/research/2026-08-15-wsl-debian-backup-and-home-recovery.md`: historical recovery evidence, measurements, decisions, and rejected alternatives.
