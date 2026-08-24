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

Generate the runtime password without printing it, record it manually in Bitwarden through a trusted local workflow, then initialize:

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

Retention keeps every snapshot for 24 hours, hourly snapshots for seven days, and daily snapshots for 30 days. The daily retention task changes snapshot metadata without reclaiming packs; the weekly prune task reclaims unreferenced storage.

## Scheduling

Windows Task Scheduler owns wake-up because a Linux timer cannot start a stopped WSL distro. From native Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  "\\wsl.localhost\Debian-Recovered\home\jack\.local\share\chezmoi\scripts\wsl-backup\home\Register-WindowsTasks.ps1"
```

The registered tasks run as the current Windows user and ask WSL to execute the root-owned program as Linux root:

- backup every 15 minutes;
- freshness monitoring every 30 minutes;
- retention daily;
- prune weekly;
- structural check weekly;
- full data read every 30 days.

The Windows-local wrapper under `%LOCALAPPDATA%\WSLHomeRestic` records secret-free operation status and notifies the interactive user with `msg.exe` if an operation fails. The monitor fails when the newest matching snapshot is more than 30 minutes old. Duplicate notices are suppressed for six hours.

Existing tasks and their next-run times are preserved by default. Use `-Force` to rebuild their definitions deliberately. Remove them with the same script's `-Remove` switch.

## Restore rule

Always restore into an empty ext4 staging directory. Do not restore directly over the live home. Validate contents, metadata, Pi sessions, histories, credentials and repositories before an atomic same-filesystem rename.
