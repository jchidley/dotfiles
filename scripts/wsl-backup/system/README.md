# Debian4 complete-distro export

The selected system backup is an ordinary **complete-distro tar/gzip export**, in addition to incremental Restic backups of `/home/jack`. It includes home and the local Restic repository without custom exclusions. Restic encryption is an implementation property, not an additional owner requirement. See the [backup contract](../../../docs/DEBIAN4-BACKUP-CONTRACT.md) for scope, storage and recovery acceptance.

## Current source candidates

- `Export-WslFullBackup.ps1`: Windows PowerShell 7 helper for `wsl --export --format tar.gz`. Requires the source already stopped; never terminates it automatically. Writes a new generation outside WSL, validates archive readability, and records size/hash metadata. Does not prove recovery or prevent concurrent source startup.
- `Test-WslFullExport.ps1`: builds a synthetic seed using Debian4, imports a fixture distro, exports it, imports the result and checks fixture content after boot. Retains both fixture registrations and generated files. It is not a real Debian4 restore or a Restic recovery test.

These are source candidates, not installed production orchestration. Running the test creates real WSL registrations and starts its restored fixture; it is not part of the side-effect-free fast lane. Production capture and isolated real restore require their own reviewed operations. The export destination must be internal Windows storage outside the source VHDX; the helper's drive-letter check alone does not verify disk identity.

## Preserved older implementations

`capture-offline-system` implements the superseded exclusion-aware design: archive an isolated read-only ext4 root, include `/var/lib/restic/home`, exclude plaintext home and staging contents. Its fixtures remain useful historical metadata/recovery evidence, but completing its production VHDX coordinator is no longer the selected work.

`Backup-WslSystem.ps1` retains the older combined external-Restic/root-freeze controller. Its Preflight/Create modes are disabled. Do not reactivate it.

## Validation and evidence

Run `bash scripts/wsl-backup/test-all fast` from WSL for the existing static/disposable component gate. It does not run the new full-export/import fixture or prove production recovery.

See [STATUS](../STATUS.md) for dated evidence and [TASKS](../TASKS.md) for remaining work. Preserve existing archives, failed partials and recovery evidence; no cleanup or source retirement is implied by the new design.
