# Local WSL home backup

This component implements the short-retention local half of the WSL backup architecture. Start with the [umbrella README](../README.md) for setup and routine commands. This page is the detailed home-snapshot reference.

It backs up `/home/jack` into an encrypted Restic repository on Debian's native ext4 filesystem. Whole-distro `tar.gz` exports and external replication are separate operations.

## Installed paths

| Purpose | Path |
|---|---|
| Program | `/usr/local/sbin/backup-wsl-home` |
| Non-secret configuration | `/etc/restic/home.conf` |
| Runtime password | `/etc/restic/home.password` |
| Repository | `/var/lib/restic/home` (pinned by repository ID) |
| Source baseline | `/var/lib/restic/home-source-baseline` |
| Persistent incident hold | `/var/lib/restic/home-retention.hold` |
| Logs (30-day retention) | `/var/log/restic-home` |
| Restic cache | `/var/cache/restic-home` |
| Consistent McFly recovery copy | `/home/jack/.local/share/mcfly/history.db.restic-backup` |

The runtime password is root-owned mode 600. Its canonical human recovery copy belongs in Bitwarden; scheduled jobs must not automate Bitwarden access.

## Install without initializing

```bash
./install.sh
```

The installer does not generate a password, initialize a repository, enroll a source baseline, enable scheduling, or modify an external disk. It creates `/etc/restic/home.conf` only when absent. On later runs it preserves the deployed file and writes the reviewed source candidate to `/etc/restic/home.conf.distributed` for explicit reconciliation.

## Verify the enrolled repository

Debian4 uses a preservation-first copy of its verified one-off repository, whose ID is pinned in `home.conf`. Do not initialize over it or regenerate its password. The retained `init` command only verifies the existing pinned repository and source baseline; it never creates a new repository. New repository provisioning is a separate explicit operation requiring a reviewed destination, credential and subsequent identity enrollment.

```bash
sudo backup-wsl-home init
```

The configured path and expected ID come from root-managed `/etc/restic/home.conf`; the recovery tester does not duplicate them.

After storing and independently checking the password in Bitwarden, record only the confirmation—not the password—in the machine configuration:

```bash
sudo install -o root -g root -m 600 /dev/null \
  /etc/restic/home.password.bitwarden-confirmed
```

Until that file exists, every scheduled operation logs a warning. Do not create the confirmation file before the Bitwarden recovery value has actually been tested.

Before recording confirmation, run `sudo test-restic-recovery-password` in Debian4 and enter the independently retrieved Bitwarden value privately. The tester unsets all runtime credential variables and passes hidden input through a private inherited descriptor; it never reads the confirmation marker.

## Operations

```bash
sudo backup-wsl-home enroll-baseline # one time, after reviewing current source health
sudo backup-wsl-home validate
sudo backup-wsl-home backup
sudo backup-wsl-home retention
sudo backup-wsl-home prune
sudo backup-wsl-home check
sudo backup-wsl-home check-read-data
sudo backup-wsl-home snapshots
sudo backup-wsl-home status
sudo backup-wsl-home restore latest /var/tmp/restic-home-restore
sudo backup-wsl-home clear-hold      # only after investigating and restoring loss
```

`backup` validates source size, file count, ownership, Pi sessions, SSH key mode, expected Debian4 landmarks, McFly SQLite integrity, and a one-time enrolled source baseline before writing a snapshot. It creates a consistent SQLite recovery copy before invoking Restic. All modifying and checking operations share a non-blocking mutex. Every repository operation verifies the configured repository ID, not merely that a repository can be opened.

The baseline records healthy bytes, files, and Pi-session counts once and is never lowered automatically. It is a coarse aggregate loss guard, not detection of every deleted file: loss below the configured thresholds, or growth followed by loss that remains above the original baseline, may not trigger a hold. Falling below 80% of any enrolled measure, losing an absolute guard or landmark, or finding missing/malformed baseline state atomically creates the incident hold. Every direct `retention` and `prune` invocation checks both source health and that hold before `forget`; restart, elapsed time, successful source restoration, and later backups do not remove it. `clear-hold` is an explicit operator action and refuses while source health remains below baseline.

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
