# Whole-system WSL backup

This directory implements the complete-system stream. It is separate from the frequent Restic `/home/jack` snapshots.

`Backup-WslSystem.ps1` creates a cold compressed export locally, validates it by importing it under a disposable WSL name, and only then promotes it from `.partial` to `.tar.gz`. It writes a SHA-256 JSON manifest and retains the newest two validated local generations. During an export it transactionally disables the six `WSL Home Restic - *` tasks so none can restart the source, then restores only the tasks that were enabled before the run.

## Install the restore validator

The validator is included inside future exports and is installed by the normal Debian bootstrap:

```bash
./install.sh
```

It checks the restored user, important paths and permissions, McFly SQLite recovery data, the included local Restic repository, required tools, Pi sessions, and `boat-data-platform` Git integrity. It does not print credentials.

## Non-disruptive preflight

Run from Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  "\\wsl.localhost\Debian-Recovered\home\jack\.local\share\chezmoi\scripts\wsl-system-backup\Backup-WslSystem.ps1" `
  -Mode Preflight
```

Preflight verifies the exact distro, free space, staging path, and installed validator. It does not stop or export WSL.

## Create and validate a generation

This operation stops `Debian-Recovered` and requires an approved maintenance window. The measured export time was about 18 minutes; disposable import and validation add several minutes.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  "\\wsl.localhost\Debian-Recovered\home\jack\.local\share\chezmoi\scripts\wsl-system-backup\Backup-WslSystem.ps1" `
  -Mode Export -ConfirmMaintenanceWindow
```

If the source was deliberately stopped and must remain stopped, avoid starting it for preflight and synchronization:

```powershell
.\Backup-WslSystem.ps1 -Mode Export -ConfirmMaintenanceWindow -SourceAlreadyStopped
```

This mode refuses to continue if the source is found running. Disposable import validation still starts a separate temporary WSL distro after export.

Default output:

```text
C:\Users\jackc\wsl-backup-staging\distro-exports\
  TIMESTAMP_Debian-Recovered.tar.gz
  TIMESTAMP_Debian-Recovered.tar.gz.manifest.json
```

The script never overwrites a generation. A failed completed export is renamed with `.partial.failed` and is not treated as a backup. Only the newest two validated `.tar.gz` generations and manifests are retained locally. Export refuses to start if any Restic task is running or if the expected six tasks are not registered.

## Validate an existing archive

```powershell
.\Backup-WslSystem.ps1 -Mode Validate -ArchivePath C:\path\generation.tar.gz
```

Validation imports under a random disposable name and unregisters it in a `finally` block. It needs enough temporary disk space for the restored VHDX.

No schedule is registered yet. Scheduling recurring downtime requires an explicit decision about the maintenance window.
