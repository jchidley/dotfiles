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

The installer is intentionally non-destructive. It does not generate a password, initialize a repository, enable scheduling, or modify an external disk.

## Initialize explicitly

**Fresh, uninitialized installations only.** Do not run these password-generation commands on Debian3 or any existing backup repository: they overwrite the runtime password. For the existing recovery-verification task, follow [`../RECOVERY-PLAN.md`](../RECOVERY-PLAN.md) without regenerating credentials or reinitializing storage.

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

Retention keeps every snapshot for 24 hours, hourly snapshots for seven days, and daily snapshots for 30 days. The Linux coordinator runs due retention without reclaiming packs; prune reclaims unreferenced storage but is not scheduled by this coordinator.

## Scheduling

Routine home-backup scheduling belongs to Linux. The integrated source installs:

| Path | Purpose |
|---|---|
| `/usr/local/sbin/wsl-home-scheduler` | Linux backup-first coordinator and retention due state |
| `/etc/systemd/system/wsl-home-scheduler.service` | One-shot coordinator service |
| `/etc/systemd/system/wsl-home-scheduler.timer` | Start after natural distro boot and repeat every 15 minutes while running |

The timer uses `Persistent=true` to reconcile once when the distro next starts naturally. It cannot start WSL, does not keep Windows from honoring `wsl --shutdown`, and contains no `wsl.exe` or PowerShell call. Backup, status, retention, locks, state, Restic, configuration, and credentials all remain inside Linux.

`setup.sh` installs the units but never enables the timer. [`MIGRATION.md`](MIGRATION.md) owns the explicit inventory, Linux preflight, cutover, rollback, observation, and later deletion procedure. Windows integration remains limited to whole-system export and future visible-consent/power boundaries.

### Historical Windows task set

The 5 September inspection found no legacy Windows tasks and verified Debian3's enabled timer and Debian-Recovered's disabled timer. [`../STATUS.md`](../STATUS.md) owns the timestamped evidence. The retained migration fixtures and rollback helpers refer to this historical task set:

- `WSL Home Restic - Backup`;
- `WSL Home Restic - Monitor`;
- `WSL Home Restic - Retention`;
- `WSL Home Restic - Prune`;
- `WSL Home Restic - Check`;
- `WSL Home Restic - Read Data Check`.

Those legacy definitions invoke `wsl.exe -d Debian-Recovered` and can restart a manually stopped distro. Do not recreate them or replay migration for Debian3. If migrating a different installation where they still exist, preserve exact definitions, disable before deleting, and require the observation gate in `MIGRATION.md`. Current absence alone does not prove how the historical deletion gate was satisfied.

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
