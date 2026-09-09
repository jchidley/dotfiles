# Debian4 backup and recovery contract

## Agreed design — 9 September 2026

Use two complementary backups:

- **Incremental home backup:** Restic snapshots of `/home/jack`, retaining file history and efficient recovery of accidental changes or deletions.
- **Complete-distro export:** an ordinary full-system tar/gzip produced by `wsl --export`, in addition to the home backup. It includes home, the local Restic repository and other root-filesystem contents without custom exclusions.

The owner selected this combination for efficiency and security considerations. Restic encrypts its repositories as part of how it works; encryption is not an independently requested requirement or the reason for choosing this backup layout. No additional system-archive encryption or new key-management scheme is required. Existing Restic credentials still need to be preserved because Restic requires them to recover its snapshots.

The full export intentionally includes plaintext home and may include credentials, temporary files, staged restores and duplicated home history. This is accepted scope, not an exclusion bug. The owner relies on physical security for storage; the archive must nevertheless be treated as sensitive and must not be published or logged by content. An unencrypted VHDX is not a security boundary either.

This decision supersedes the exclusion-aware archive design of 8 September. `capture-offline-system` and its tests remain preserved prior-design implementation/evidence, not the selected production path. Do not complete its VHDX mount coordinator merely to satisfy that superseded plan.

## Storage and capture

The primary full export belongs on the Windows internal drive, outside Debian4's VHDX, including through aliases. External copying is separate replication. Storage on the same physical drive protects against logical loss, not failure or loss of that drive.

Capture requires an approved maintenance window and a stopped source distro. Do not automatically terminate Debian4 or wake it for routine polling. The source must not be started during capture; before/after inventory checks alone do not establish exclusive access for the entire interval.

`system/Export-WslFullBackup.ps1` is the current source candidate. It requires an already-stopped distro, rejects redirected destination components, runs `wsl --export --format tar.gz`, checks gzip and archive readability, and publishes a new generation with archive size, SHA-256, distro, time and empty exclusions. Failed partial output is retained. Its manifest explicitly says `restoreTested=false`.

Source review and validation remain necessary before accepting this candidate for production. In particular, a drive-letter path alone does not prove an internal disk, and the stopped-state checks do not prevent a concurrent start. No old root-freeze controller is to be re-enabled.

## Home history and scheduling

Existing Linux-owned Restic home backups, systemd scheduling, operation locks and deletion holds remain unchanged. A full export does not replace incremental history, and the latest Restic snapshot can predate the export. Do not claim a single atomic snapshot spanning both operations.

The existing GPG-backed Restic password provider and independent Bitwarden recovery route remain necessary implementation details, not a request for additional encryption. No new key, AK service, Windows password process or automated Bitwarden access is needed.

Do not add Windows scheduling or polling of routine Linux-owned work. Backup cadence, deployment, retention and cleanup are not changed by this design decision.

## Recovery acceptance

1. Verify the full archive's manifest, size and checksum.
2. Import it into a new disposable destination, without replacing an existing distro.
3. Establish isolation before first boot: prevent production services, schedules and networking from acting on restored state.
4. Verify actual system/home content and relevant Linux ownership, modes, links and metadata after import and boot.
5. Separately verify that retained Restic history can be authenticated and restored with the independently recoverable password. Direct full-system recovery does not require reconstructing home from Restic first.
6. Preserve original distros and recovery evidence until the real recovery and reconciliation gates pass; retirement requires separate approval.

`system/Test-WslFullExport.ps1` tests a synthetic export/import/boot round trip. Its repository landmark is a text fixture, not a real Restic repository. It retains imported fixture distros and generated files. It does not establish real Debian4 recovery, complete metadata preservation, independent password recovery or network isolation.

This document records the owner's selected design, not a claim that production capture, real restore or source retirement has been verified in this session. Dated evidence belongs in `scripts/wsl-backup/STATUS.md`; outstanding work belongs in `TASKS.md`.
