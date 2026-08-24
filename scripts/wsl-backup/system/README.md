# Whole-system WSL backup

This component implements the complete-system stream. Start with the [umbrella README](../README.md) for setup and routine commands. This page is the detailed whole-system reference.

It is separate from the frequent Restic `/home/jack` snapshots.

`Backup-WslSystem.ps1` creates a cold compressed export locally, validates it by importing it under a disposable WSL name, and only then promotes it from `.partial` to `.tar.gz`. It writes a SHA-256 JSON manifest and retains the newest two validated local generations. During an export it transactionally disables the six `WSL Home Restic - *` tasks so none can restart the source, then restores only the tasks that were enabled before the run.

## Install the restore validator

The validator is included inside future exports and is installed by the normal Debian bootstrap:

```bash
./install.sh
```

It checks the restored user, important paths and permissions, McFly SQLite recovery data, the included local Restic repository, required tools, Pi sessions, and `boat-data-platform` Git integrity. It does not print credentials.

## Non-disruptive preflight

Run from PowerShell 7 (`pwsh.exe`); Windows PowerShell 5.1 is unsupported:

```powershell
pwsh.exe -NoLogo -NoProfile -File `
  "\\wsl.localhost\Debian-Recovered\home\jack\.local\share\chezmoi\scripts\wsl-backup\system\Backup-WslSystem.ps1" `
  -Mode Preflight
```

Preflight verifies the exact distro, free space, staging path, and installed validator. It does not stop or export WSL.

## Create and validate a generation

This operation stops `Debian-Recovered` and requires an approved maintenance window. The measured export time was about 18 minutes; disposable import and validation add several minutes.

```powershell
pwsh.exe -NoLogo -NoProfile -File `
  "\\wsl.localhost\Debian-Recovered\home\jack\.local\share\chezmoi\scripts\wsl-backup\system\Backup-WslSystem.ps1" `
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

Before task suspension, export atomically writes `%LOCALAPPDATA%\WSLSystemBackup\active-run.json` with the exact prior task state, process identity, selected paths and current stage. Normal completion removes the journal. If PowerShell is killed or Windows restarts, the journal remains for explicit recovery. Durable stage logs are retained under `%LOCALAPPDATA%\WSLSystemBackup\logs`.

## Validate an existing archive

```powershell
.\Backup-WslSystem.ps1 -Mode Validate -ArchivePath C:\path\generation.tar.gz
```

Validation imports under a random disposable name and unregisters it in a `finally` block. It needs enough temporary disk space for the restored VHDX.

## Status, recovery and cleanup

These modes do not perform an export:

```powershell
.\Backup-WslSystem.ps1 -Mode Status
.\Backup-WslSystem.ps1 -Mode Recover
.\Backup-WslSystem.ps1 -Mode ValidateManifest -ArchivePath C:\path\archive.tar.gz.manifest.json
.\Backup-WslSystem.ps1 -Mode Cleanup -ConfirmCleanup -RemoveFailedArtifacts
.\Backup-WslSystem.ps1 -Mode Cleanup -ConfirmCleanup -RemoveValidationDirectories
```

`Status` reports active or abandoned journals, task state, failed export artifacts, validation directories and malformed manifests without hashing multi-gigabyte archives. `Recover` refuses to act while the recorded process is still active and otherwise restores the exact pre-run task state. Cleanup is explicit and refuses to run while any journal exists. It never removes validated generations.

`ValidateManifest` performs a complete archive-size, schema, validation-evidence and SHA-256 check. Every generated manifest also receives a fast structural check before generation retention runs.

## Tests

From inside WSL, the umbrella fast lane runs the self-contained PowerShell suite, static analysis, and the other backup contract tests:

```bash
./scripts/wsl-backup/test-all fast
```

The system suite uses injected Task Scheduler adapters and disposable small files; it does not invoke WSL or modify production tasks. No schedule is registered yet. Scheduling recurring downtime requires an explicit decision about the maintenance window.
