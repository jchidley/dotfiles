# Local WSL home backup

This component implements the short-retention local half of the WSL backup architecture. Start with the [umbrella README](../README.md) for setup and routine commands. This page is the detailed home-snapshot reference.

It backs up `/home/jack` into an encrypted Restic repository on Debian's native ext4 filesystem. Whole-distro `tar.gz` exports and external replication are separate operations.

## Installed paths

| Purpose | Path |
|---|---|
| Program | `/usr/local/sbin/backup-wsl-home` |
| Non-secret configuration | `/etc/restic/home.conf` |
| Runtime password | `/etc/restic/home.password` |
| Repository | `/var/lib/restic/home` |
| Logs (30-day retention) | `/var/log/restic-home` |
| Restic cache | `/var/cache/restic-home` |
| Consistent McFly recovery copy | `/home/jack/.local/share/mcfly/history.db.restic-backup` |

The runtime password is root-owned mode 600. Its canonical human recovery copy belongs in Bitwarden; scheduled jobs must not automate Bitwarden access.

## Install without initializing

```bash
./install.sh
```

The installer does not generate a password, initialize a repository, enable scheduling, or modify an external disk. It **does replace `/etc/restic/home.conf`** with the source configuration, so review and preserve installation-specific settings before an update; it is not a read-only verification command.

## Initialize explicitly

**Fresh, uninitialized installations only.** For current work this means a separately approved new Debian4 repository after its backup contents are selected. Never run these password-generation commands against Debian-Recovered, Debian-Backup, or any existing repository: they overwrite the runtime password. The retired Debian3 recovery plan is historical and is not an initialization procedure.

For a fresh installation, generate the runtime password without printing it, record it manually in Bitwarden through a trusted local workflow, then initialize:

```bash
sudo install -o root -g root -m 600 /dev/null /etc/restic/home.password
head -c 48 /dev/urandom | base64 | sudo tee /etc/restic/home.password >/dev/null
sudo chmod 600 /etc/restic/home.password
sudo /usr/local/sbin/backup-wsl-home init
```

Never initialize an unexpected non-empty path. The program refuses to do so.

After storing and independently checking the password in Bitwarden, record only the confirmation—not the password—in the machine configuration:

```bash
sudo install -o root -g root -m 600 /dev/null \
  /etc/restic/home.password.bitwarden-confirmed
```

Until that file exists, every scheduled operation logs a warning. Do not create the confirmation file before the Bitwarden recovery value has actually been tested.

The uncommitted `test-restic-recovery-password` candidate was designed for the now-retired Debian3 repository. Do not execute it as a current recovery step. Its hidden-input, no-runtime-fallback design may be reviewed and adapted later for Debian4's independently supplied recovery credential.

## Operations

```bash
sudo backup-wsl-home validate
sudo backup-wsl-home backup
sudo backup-wsl-home retention
sudo backup-wsl-home prune
sudo backup-wsl-home check
sudo backup-wsl-home check-read-data
sudo backup-wsl-home snapshots
sudo backup-wsl-home status
sudo backup-wsl-home restore latest /var/tmp/restic-home-restore
```

`backup` validates source size, file count, ownership, Pi sessions, SSH key mode, expected landmarks, and McFly SQLite integrity before writing a snapshot. It creates a consistent SQLite recovery copy before invoking Restic. All modifying and checking operations share a non-blocking mutex.

Retention uses `--keep-within 24h --keep-hourly 168 --keep-daily 30`: every snapshot within 24 hours plus representatives of the last 168 hours and 30 days that have snapshots. Sparse backup history may therefore span more than seven or 30 calendar days. The Linux coordinator runs due retention without reclaiming packs; prune reclaims unreferenced storage but is not scheduled by this coordinator.

## Scheduling

Routine home-backup scheduling belongs to Linux. The integrated source installs:

| Path | Purpose |
|---|---|
| `/usr/local/sbin/wsl-home-scheduler` | Linux backup-first coordinator and retention due state |
| `/etc/systemd/system/wsl-home-scheduler.service` | One-shot coordinator service |
| `/etc/systemd/system/wsl-home-scheduler.timer` | Start after natural distro boot and repeat every 15 minutes while running |

The timer's `OnBootSec=2min` provides an opportunity after natural distro startup; `OnUnitActiveSec=15min` provides subsequent opportunities while running. Although the unit contains `Persistent=true`, that setting's catch-up behavior applies to calendar timers and is not the mechanism for this monotonic timer. It cannot start WSL, does not keep Windows from honoring `wsl --shutdown`, and contains no `wsl.exe` or PowerShell call. Backup, status, retention, locks, state, Restic, configuration, and credentials all remain inside Linux.

`setup.sh` installs the units but never enables the timer. [`MIGRATION.md`](MIGRATION.md) owns the explicit inventory, Linux preflight, cutover, rollback, observation, and later deletion procedure. Windows integration remains limited to whole-system export and future visible-consent/power boundaries.

### Historical Windows task set

The 5 September inspection found no legacy Windows tasks and verified Debian3's enabled timer and Debian-Recovered's disabled timer. [`../STATUS.md`](../STATUS.md) owns the timestamped evidence. The retained migration fixtures and rollback helpers refer to this historical task set:

- `WSL Home Restic - Backup`;
- `WSL Home Restic - Monitor`;
- `WSL Home Restic - Retention`;
- `WSL Home Restic - Prune`;
- `WSL Home Restic - Check`;
- `WSL Home Restic - Read Data Check`.

Those legacy definitions invoke `wsl.exe -d Debian-Recovered` and can restart it. Do not recreate them or replay the retired migration. If migrating a different installation where they still exist, preserve exact definitions, disable before deleting, and require the observation gate in `MIGRATION.md`. Current absence alone does not prove how the historical deletion gate was satisfied.

Prune and full-data-check scheduling remain pending the Linux-origin request/Windows-visible-consent bridge. The Linux timer does not run either operation automatically.

## Tests

Use the umbrella runner from inside WSL:

```bash
./scripts/wsl-backup/test-all fast
./scripts/wsl-backup/test-all integration
```

The fast lane uses a disposable install root and fake Windows adapters. The integration lane exercises a real disposable Restic repository and staged restore.

## Restore rule

Always restore into an empty ext4 staging directory. Do not restore directly over the live home. Validate contents, metadata, Pi sessions, histories, credentials and repositories before an atomic same-filesystem rename.
