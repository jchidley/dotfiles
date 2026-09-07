# Whole-system WSL backup

> **Uncommitted, undeployed candidate—not an execution-ready Debian4 runbook.** The descriptions below cover the preserved Debian3 adaptation. Focused checks passed, but final full-lane validation and real disposable-import isolation remain unproven. The [Debian4 plan](../../../docs/DEBIAN4-PLAN.md) governs current work: select target capabilities/data before defining its restore contract. Do not apply the PostgreSQL/history landmarks below automatically to the clean build.

This component creates a cold complete-distro export, validates it through a disposable import, writes a SHA-256 manifest, and retains two validated generations per source distro. It is separate from the frequent Restic `/home/jack` snapshots.

Export, archive storage, disposable import execution, and deployment require the approvals in [`../RECOVERY-PLAN.md`](../RECOVERY-PLAN.md). Source tests do not grant those approvals.

## Coordination contracts

The controller requires an explicit scheduling model:

- `LegacyWindowsTasks` (the default for compatibility) requires exactly six non-running `WSL Home Restic - *` tasks, records their enabled state, disables them transactionally, and restores that state.
- `LinuxSystemd` requires **zero** matching Windows tasks. If the source is running, it records and temporarily stops the Linux timer/service before sync and termination, then restores the timer's runtime state after WSL restarts. The timer remains enabled on disk, so an interrupted export that leaves the distro stopped does not need to start it merely for recovery.

A schema-2 crash journal records the selected contract. Recovery fails closed on malformed or older journal state. Existing schema-1 archive manifests remain inspectable as legacy evidence, but do not acquire the stronger Debian3 validation claims.

## Debian3 restore contract

The current validator checks the inspected Debian3 layout without decrypting or printing sensitive data:

- user and home ownership, SSH ownership/mode, and Pi sessions/transcripts;
- McFly recovery SQLite integrity and the chezmoi Git repository;
- AK vault configuration plus the presence and permissions of encrypted GPG private-key material;
- installed Restic, scheduler, Node/npm/Pi, Git, SQLite, and PostgreSQL tools;
- the included encrypted Restic repository using its installed runtime credential;
- retained `roles.sql`, readable `boatdata_direct` and `boatdata_staging` dumps, and PostgreSQL cluster control data.

It deliberately does not use the absent `~/boat-data-platform` landmark or minimum whole-home file/session counts. Independent recovery-password testing is a separate gate.

## Disposable-import isolation

Validation imports the archive as WSL2 but does not boot it. It mounts the disposable VHD offline, preserves that copy's original `wsl.conf`, and writes a validation-only `[boot] systemd=false` configuration before first boot. Therefore the recovered timer, PostgreSQL, and every other recovered systemd service cannot auto-start or contact production. The validator confirms PID 1 is not systemd and rejects running PostgreSQL or backup processes before inspecting data. It performs no network operation.

Offline VHD mounting may require an elevated approved validation process; the actual import remains separately approval-gated. The random distro, mount, temporary configuration, and validation directory are cleaned in `finally`. Cleanup never targets another registered distro or its storage.

## Install the restore validator

The ordinary non-destructive setup installs the validator:

```bash
./install.sh
```

It does not export, initialize Restic, enable a timer, or register Windows tasks.

## Non-disruptive preflight

From PowerShell 7, select Debian3 and its Linux-owned scheduler explicitly:

```powershell
.\Backup-WslSystem.ps1 -Mode Preflight `
  -Distro Debian3 -BackupCoordination LinuxSystemd
```

Preflight checks registration, free space, the coordination contract, and—unless `-SourceAlreadyStopped` is supplied—the installed validator. `-SourceAlreadyStopped` refuses a running source and does not start a stopped one merely to inspect it.

## Create and validate a generation

Only after storage and downtime approval:

```powershell
.\Backup-WslSystem.ps1 -Mode Export `
  -Distro Debian3 -BackupCoordination LinuxSystemd `
  -StagingDirectory 'D:\protected\wsl-exports' `
  -ConfirmMaintenanceWindow
```

For an already stopped source that must remain stopped:

```powershell
.\Backup-WslSystem.ps1 -Mode Export `
  -Distro Debian3 -BackupCoordination LinuxSystemd `
  -SourceAlreadyStopped -ConfirmMaintenanceWindow
```

A source that was running is synchronized, terminated for the export, and restarted afterward. A source declared already stopped is never started. The archive remains `.partial` until disposable validation passes. A failed completed export becomes `.partial.failed`; it is never promoted. Retention is distro-scoped and does not select Debian-Recovered generations while processing Debian3.

## Existing archives, status, recovery, and cleanup

These modes do not create an export:

```powershell
.\Backup-WslSystem.ps1 -Mode Status -Distro Debian3 -BackupCoordination LinuxSystemd
.\Backup-WslSystem.ps1 -Mode Recover -Distro Debian3 -BackupCoordination LinuxSystemd
.\Backup-WslSystem.ps1 -Mode ValidateManifest -ArchivePath C:\path\archive.tar.gz.manifest.json
.\Backup-WslSystem.ps1 -Mode Cleanup -ConfirmCleanup -RemoveFailedArtifacts
.\Backup-WslSystem.ps1 -Mode Cleanup -ConfirmCleanup -RemoveValidationDirectories
```

`Validate` performs a disposable import and therefore requires test-import approval:

```powershell
.\Backup-WslSystem.ps1 -Mode Validate -ArchivePath C:\path\generation.tar.gz
```

Cleanup refuses while a run journal exists, restricts validation-directory deletion to unregistered directories under its own root, and never removes validated generations. `ValidateManifest` checks schema, archive size, validation evidence, and SHA-256.

## Tests

From WSL in the exact canonical source checkout:

```bash
./scripts/wsl-backup/test-all fast
```

The fast lane uses disposable files and injected task adapters. It does not invoke an export/import, modify real schedulers, deploy files, or access production credentials.
