# Debian4 completion and selective migration plan

This is the active plan for Debian4. It authorizes no secret access, production operation, service change, external write, privilege elevation, distro removal, or evidence deletion by itself.

## Current position

Debian4 is the clean successor. Full-export implementation, production cold capture, real separate-distro recovery assurance, and source integration are complete. The current work is closeout of retained recovered material and preservation sources, not another backup or recovery run.

Debian-Recovered, Debian2, and Debian3 are retired. Debian-Backup remains a stopped extraction/verification source backed by the immutable August forensic image. Preserve both until Debian-Backup receives a final inventory and the owner decides whether to retire it.

The accepted backup is Linux-owned incremental Restic history for `/home/jack` plus a Windows-owned complete Debian4 export on internal Windows storage. See the [backup contract](DEBIAN4-BACKUP-CONTRACT.md) for durable design and recovery constraints, [`STATUS.md`](../scripts/wsl-backup/STATUS.md) for current evidence locations, and [`TASKS.md`](../scripts/wsl-backup/TASKS.md) for the incomplete queue.

## Closeout sequence

1. Review and publish the current documentation reconciliation.
2. With separate approval to start Debian4 and account for its enabled backup timer, inspect `/home/jack/recovery/debian-final-recovery-20260909`. Record dispositions and promote only selected material with provenance and conflict checks.
3. Perform Debian-Backup's final preservation inventory without booting or modifying it unless a separately reviewed operation requires that access. Decide whether it can be retired.
4. If retirement is accepted, obtain explicit owner approval before unregistering Debian-Backup. Continue preserving the immutable forensic image unless its removal is separately approved.
5. Decide retention or cleanup individually for the recovery distro and restored tree, fixture and capture-clone distros, failed generations, and evidence directories. Preserve the accepted production archive and operationally required recovery evidence.
6. Record the final recovered-content dispositions, Debian4 running/stopped state, Debian-Backup outcome, and retained artifacts; then publish the final closeout record.

## System roles and boundaries

| System or artifact | Current role | Boundary |
|---|---|---|
| Debian4 | Clean successor and home of the retained recovered-material workspace | Starting it requires separate approval; account for the enabled Linux backup timer. Do not repeat production backup or recovery tests. |
| Debian-Backup | Stopped writable clone used for controlled inspection | Do not boot, compact, optimize, repair, unregister, or delete it without the applicable reviewed operation and approval. |
| Immutable August forensic image | Preservation source for Debian-Backup | Keep read-only and preserved unless removal is separately approved. |
| `Debian4-RecoveryTest-20260909A` | Retained proof of real recovery, including restored Restic history | Keep stopped; unregistering or deleting its restored tree/evidence requires explicit approval. |
| Production archive and `FullCapture-Debian4-091d2190` | Accepted full-export backup and retained capture source | Preserve the archive and required evidence; cleanup of the clone is a separate decision. |
| Fixture distros, failed generations, and evidence | Diagnostic and assurance evidence | Decide retention individually; do not bulk-clean or unregister. |

## Completed constraints that remain operational

- Do not repeat production export, archive hashing/full listing, real import/boot, Restic full-data checking, or older-snapshot restore. Existing evidence is referenced from [`STATUS.md`](../scripts/wsl-backup/STATUS.md).
- Do not claim an exact ACL/user-xattr/capability comparison; retained source examples were unavailable and this limitation is accepted.
- Firewall changes and elevated offline-VHD isolation are not required for the accepted recovery.
- Linux owns routine Restic scheduling. Do not add Windows polling, waking, or routine scheduling.
- Cleanup, source restart, and retirement remain separate decisions with their existing approval boundaries.

## Deferred and out of scope

Optional Debian4 replication is deferred and is not a closeout prerequisite. PostgreSQL activation, broader backup scheduling changes, long-job consent deployment, and prune/full-data-check scheduling are separate workflow decisions. Do not revive the cancelled Debian-Recovered replication.

## Closeout stopping point

Closeout is complete only when recovered material has recorded dispositions, Debian-Backup has an explicit retain/retire outcome, artifact retention decisions are recorded, the final Debian4 running/stopped state is documented, and the reconciled records are committed and pushed. No destructive action is implied by reaching a review decision; execute each approved removal separately and verify its exact effects.
