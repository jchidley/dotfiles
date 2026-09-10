# WSL backup and recovery tasks

Only current incomplete work belongs here. [`STATUS.md`](STATUS.md) records the current verified position and evidence locations; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequencing and approval boundaries; the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) owns the selected design and recovery acceptance criteria.

## Current priority

No required Debian4 post-closeout operation remains. [`STATUS.md`](STATUS.md) records the accepted backups, retained promotions and Pi recovery corpus, approved cleanup, Terminal acceptance, canonical test result, and final running state.

## Completed work that must not be repeated

- Production schema-3 cold export, independent archive verification, and real recovery under `Debian4-RecoveryTest-20260909A` are complete. See [`STATUS.md`](STATUS.md) and the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md).
- Source/documentation integration passed the canonical fast gate and pinned PSScriptAnalyzer 1.25.0, and was published as commit `285f28c`.
- The real recovery authenticated the expected embedded Restic repository, completed `check --read-data`, and verified an older-snapshot restore. Do not repeat production capture, archive hashing/full listing, import/boot, or Restic recovery testing.
- Exact ACL/user-xattr/capability comparison is not claimed because corresponding retained source examples were unavailable. This limitation is accepted and is not a remaining closeout gate.
- Firewall changes and elevated offline-VHD isolation were rejected as unnecessary for the completed recovery.

## Preservation and deferred work

- Preserve the accepted archive, Windows-side Restic replica, promoted selections, and published private Pi recovery corpus. Approved recovery-workspace and redundant-staging deletions are complete; do not recreate them.
- Do not recreate deleted forensic/recovery evidence or repeat production export/recovery tests merely to replace intentionally removed proof.
- The one-off encrypted Restic repository replica under `C:/WSL-Backups/Debian4/restic/20260910T000023Z-6090f188/` protects against VHDX loss but not failure or loss of the internal physical disk. Further external replication remains optional; the cancelled Debian-Recovered replication must not be revived.
- PostgreSQL activation, broader backup scheduling changes, long-job consent deployment, and prune/full-data-check scheduling remain separate workflow decisions.
- Debian-Recovered, Debian-Backup, Debian2, and Debian3 are retired.
