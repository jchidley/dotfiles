# WSL backup and recovery tasks

Only current incomplete work belongs here. [`STATUS.md`](STATUS.md) records the current verified position and evidence locations; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequencing and approval boundaries; the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) owns the selected design and recovery acceptance criteria.

## Current priority

No required Debian4 backup-assurance closeout operation remains. [`STATUS.md`](STATUS.md) records the accepted archive/recovery, recovered-material dispositions, Debian-Backup retirement, approved cleanup, final stopped state, and retained artifacts.

## Completed work that must not be repeated

- Production schema-3 cold export, independent archive verification, and real recovery under `Debian4-RecoveryTest-20260909A` are complete. See [`STATUS.md`](STATUS.md) and the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md).
- Source/documentation integration passed the canonical fast gate and pinned PSScriptAnalyzer 1.25.0, and was published as commit `285f28c`.
- The real recovery authenticated the expected embedded Restic repository, completed `check --read-data`, and verified an older-snapshot restore. Do not repeat production capture, archive hashing/full listing, import/boot, or Restic recovery testing.
- Exact ACL/user-xattr/capability comparison is not claimed because corresponding retained source examples were unavailable. This limitation is accepted and is not a remaining closeout gate.
- Firewall changes and elevated offline-VHD isolation were rejected as unnecessary for the completed recovery.

## Preservation and deferred work

- Preserve the accepted archive, Debian4 recovered-material workspace, and promoted selections. Their recorded retention is not permission for later cleanup.
- The divergent recovered boat-data-platform snapshot remains available for a separately scoped branch-level review; it is not a backup-assurance closeout requirement.
- Optional Debian4 replication is deferred and is not required. The cancelled Debian-Recovered replication must not be revived.
- PostgreSQL activation, broader backup scheduling changes, long-job consent deployment, and prune/full-data-check scheduling remain separate workflow decisions.
- Debian-Recovered, Debian-Backup, Debian2, and Debian3 are retired.
