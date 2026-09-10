# Debian4 completion and selective migration plan

This is the active plan for Debian4. It authorizes no secret access, production operation, service change, external write, privilege elevation, distro removal, or evidence deletion by itself.

## Current position

Debian4 is the clean successor. Full-export implementation, production cold capture, real separate-distro recovery assurance, source integration, Debian-Backup retirement, external forensic cleanup, post-promotion backup verification, a one-off Windows-side Restic repository replica, retained-material disposition, documentation reconciliation, Terminal UI verification, the canonical source gate, and the final running-state decision are complete.

Debian-Recovered, Debian-Backup, Debian2, and Debian3 are retired. After selected recovery material was verified in Debian4 and the owner declared further forensic recovery exhausted, the Debian-Backup clone, immutable August image, Windows recovery workspaces/evidence, and imported recovery-test distro were removed by explicit approval.

The accepted backup is Linux-owned incremental Restic history for `/home/jack` plus a Windows-owned complete Debian4 export on internal Windows storage. See the [backup contract](DEBIAN4-BACKUP-CONTRACT.md) for durable design and recovery constraints, [`STATUS.md`](../scripts/wsl-backup/STATUS.md) for current evidence locations, and [`TASKS.md`](../scripts/wsl-backup/TASKS.md) for the incomplete queue.

## Completed closeout

- Reviewed the transferred recovered-material package inside Debian4 with its Linux timer controlled; promoted four isolated project snapshots plus selected celestial-navigation and woodworking files with provenance and SHA-256 verification.
- During final reconciliation, promoted the divergent boat-data-platform snapshot as a fifth inert project tree and promoted the archive-only boat service, research notes, Symphony prototypes, and private personal files under `/home/jack/recovered-material/`. Independent SHA-256 verification passed, private modes were restricted, and no recovered content was executed.
- Completed Debian-Backup's non-booting inventory, then removed its redundant writable clone with explicit approval.
- Removed explicitly approved fixture registrations/directories, specialist tools and recovery-test distros, superseded generation, production cold clone, immutable August image, Windows recovery workspaces/evidence, and dated test artifacts.
- Retained the accepted archive, Windows-side Restic replica, and promoted selections; removed `/home/jack/recovery/debian-final-recovery-20260909` after its wanted material was promoted and verified.
- Verified Debian4 stopped at the cleanup checkpoint; after a later unknown restart, the owner explicitly selected the running final state so the enabled Linux timer can continue normally.

## System roles and boundaries

| System or artifact | Current role | Boundary |
|---|---|---|
| Debian4 | Clean successor and home of promoted recovered selections plus the intentionally retained private Pi recovery corpus | Running by owner decision. Its Linux backup timer is enabled. Do not query or operate production backup state, delete retained content, or stop/restart it without the applicable review and approval. |
| Debian-Backup | Retired after final preservation inventory | Registration and writable clone storage are absent. |
| Immutable August forensic image | Exhausted forensic source | Removed after explicit owner acceptance that no further recovery was wanted. |
| `Debian4-RecoveryTest-20260909A` | Completed proof of real recovery | Registration, restored tree, and internal evidence were removed after the result was recorded and accepted. |
| Production archive | Accepted full-export backup | Preserve generation `20260909T170315Z-091d2190` and its manifest. The cold clone was removed by explicit approval. |
| Windows-side Restic replica | One-off encrypted copy outside Debian4's VHDX | Preserve `C:/WSL-Backups/Debian4/restic/20260910T000023Z-6090f188/`. It contains pinned snapshot `6090f188…`, passed `restic check`, and remains on the same physical disk. |
| Fixture and superseded artifacts | Completed disposable assurance evidence | Registrations, directories, reports, and superseded generation were removed by explicit approval. |

## Completed constraints that remain operational

- Do not repeat production export, archive hashing/full listing, real import/boot, Restic full-data checking, or older-snapshot restore. Existing evidence is referenced from [`STATUS.md`](../scripts/wsl-backup/STATUS.md).
- Do not claim an exact ACL/user-xattr/capability comparison; retained source examples were unavailable and this limitation is accepted.
- Firewall changes and elevated offline-VHD isolation are not required for the accepted recovery.
- Linux owns routine Restic scheduling. Do not add Windows polling, waking, or routine scheduling.
- Any future cleanup of the accepted archive or Debian4 recovered/promoted material remains a separate approval boundary.

## Completion result

No required post-closeout operation remains. Future work begins from [`TASKS.md`](../scripts/wsl-backup/TASKS.md) and requires its own scope and approvals.

## Deferred and out of scope

The completed Windows-side Restic replica protects against VHDX loss but not physical-disk loss. Further external replication is optional and not a closeout prerequisite. PostgreSQL activation, broader backup scheduling changes, long-job consent deployment, and prune/full-data-check scheduling are separate workflow decisions. Do not revive the cancelled Debian-Recovered replication.

## Current stopping point

Debian-Backup recovery and Debian4 post-closeout reconciliation are complete. External forensic artifacts, the final in-Debian4 recovery workspace, redundant import staging, disposable import fixtures, and public-duplicate source snapshots are removed. Wanted selections and the verified PostgreSQL package are promoted; the private Pi recovery corpus is intentionally retained; backup coverage is verified; Terminal UI is accepted; the canonical gate passed; and Debian4 is intentionally running. No retained artifact may be removed without explicit approval.
