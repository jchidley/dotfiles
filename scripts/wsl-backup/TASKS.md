# WSL backup and recovery tasks

Only current incomplete work belongs here. [`STATUS.md`](STATUS.md) records the current verified position and evidence locations; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequencing and approval boundaries; the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) owns the selected design and recovery acceptance criteria.

## Current priority

1. Review, commit and push the current four-file documentation reconciliation. It removes superseded claims that full-export recovery and source integration remain incomplete.
2. Review and disposition `/home/jack/recovery/debian-final-recovery-20260909` in Debian4. Record each selected promotion or retention decision. Starting Debian4 requires separate owner approval and must account for its enabled Linux backup timer.
3. Perform a final preservation inventory for Debian-Backup. If the inventory supports retirement, obtain explicit owner approval before unregistering it. Preserve the immutable forensic image unless its removal is separately approved.
4. Decide retention or cleanup separately for the recovery distro and restored tree, fixture and capture-clone distros, failed generations, and evidence directories. Preserve the accepted production archive and evidence required to demonstrate recovery. Any unregister or deletion requires explicit owner approval.
5. Reconcile the records after those decisions, including recovered-content dispositions, Debian4 running/stopped state, Debian-Backup outcome, and retained artifacts; then commit and push one final closeout record.

## Completed work that must not be repeated

- Production schema-3 cold export, independent archive verification, and real recovery under `Debian4-RecoveryTest-20260909A` are complete. See [`STATUS.md`](STATUS.md) and the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md).
- Source/documentation integration passed the canonical fast gate and pinned PSScriptAnalyzer 1.25.0, and was published as commit `285f28c`.
- The real recovery authenticated the expected embedded Restic repository, completed `check --read-data`, and verified an older-snapshot restore. Do not repeat production capture, archive hashing/full listing, import/boot, or Restic recovery testing.
- Exact ACL/user-xattr/capability comparison is not claimed because corresponding retained source examples were unavailable. This limitation is accepted and is not a remaining closeout gate.
- Firewall changes and elevated offline-VHD isolation were rejected as unnecessary for the completed recovery.

## Preservation and deferred work

- Preserve Debian-Backup, the immutable forensic image, the accepted archive and cold clone, the recovery distro and restored tree, failed generations, fixtures, and prior evidence until their individual dispositions are approved.
- Optional Debian4 replication is deferred and is not required for closeout. The cancelled Debian-Recovered replication must not be revived.
- PostgreSQL activation, broader backup scheduling changes, long-job consent deployment, and prune/full-data-check scheduling are outside this closeout.
- Debian2 and Debian3 are retired. Debian-Recovered was retired under its separate approval. Historical fixtures that name retired systems remain evidence unless separately approved for cleanup.
