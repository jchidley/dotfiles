# Debian4 completion and selective migration plan

This is the active plan for Debian4. It authorizes no secret access, production operation, service change, external write, privilege elevation, distro removal, or evidence deletion by itself.

## Current position

Debian4 is the clean successor. Full-export implementation, production cold capture, real separate-distro recovery assurance, source integration, recovered-material review, preservation decisions, and cleanup are complete.

Debian-Recovered, Debian-Backup, Debian2, and Debian3 are retired. The immutable August forensic image remains preserved and read-only; the redundant registered Debian-Backup clone was removed after its final inventory and explicit owner approval.

The accepted backup is Linux-owned incremental Restic history for `/home/jack` plus a Windows-owned complete Debian4 export on internal Windows storage. See the [backup contract](DEBIAN4-BACKUP-CONTRACT.md) for durable design and recovery constraints, [`STATUS.md`](../scripts/wsl-backup/STATUS.md) for current evidence locations, and [`TASKS.md`](../scripts/wsl-backup/TASKS.md) for the incomplete queue.

## Completed closeout

- Reviewed the transferred recovered-material package inside Debian4 with its Linux timer controlled; promoted four isolated project snapshots plus selected celestial-navigation and woodworking files with provenance and SHA-256 verification.
- Retained the divergent boat-data-platform snapshot for separate branch-level review, retained private/research/prototype material as evidence, and required no promotion for public duplicates or older public history.
- Completed Debian-Backup's non-booting inventory, then unregistered its redundant writable clone with explicit approval while preserving the immutable image.
- Removed explicitly approved disposable fixture registrations/directories, the specialist tools distro, the superseded schema-1 generation, production cold clone, and disposable forensic working VHDX.
- Retained the accepted archive, real-recovery distro/restored tree/evidence, immutable forensic image, evidence roots, recovered-material workspaces, and promoted selections.
- Verified Debian4 and the retained recovery distro stopped at closeout.

## System roles and boundaries

| System or artifact | Current role | Boundary |
|---|---|---|
| Debian4 | Clean successor and home of the retained recovered-material workspace and promoted selections | Currently stopped. Its Linux backup timer remains enabled for natural future starts. Do not repeat production backup or recovery tests. |
| Debian-Backup | Retired after final preservation inventory | Registration and writable clone storage are absent. |
| Immutable August forensic image | Preserved original forensic source | Keep read-only and preserved unless removal is separately approved. |
| `Debian4-RecoveryTest-20260909A` | Retained proof of real recovery, including restored Restic history | Kept stopped; unregistering or deleting its restored tree/evidence requires explicit approval. |
| Production archive | Accepted full-export backup | Preserve generation `20260909T170315Z-091d2190` and required evidence. The cold clone was removed by explicit approval. |
| Fixture and superseded artifacts | Completed disposable assurance evidence | Registrations/directories and the superseded schema-1 generation were removed by explicit approval; retained reports remain evidence. |

## Completed constraints that remain operational

- Do not repeat production export, archive hashing/full listing, real import/boot, Restic full-data checking, or older-snapshot restore. Existing evidence is referenced from [`STATUS.md`](../scripts/wsl-backup/STATUS.md).
- Do not claim an exact ACL/user-xattr/capability comparison; retained source examples were unavailable and this limitation is accepted.
- Firewall changes and elevated offline-VHD isolation are not required for the accepted recovery.
- Linux owns routine Restic scheduling. Do not add Windows polling, waking, or routine scheduling.
- Any future cleanup of retained artifacts or start of a stopped recovery distro remains a separate approval boundary.

## Deferred and out of scope

Optional Debian4 replication is deferred and is not a closeout prerequisite. PostgreSQL activation, broader backup scheduling changes, long-job consent deployment, and prune/full-data-check scheduling are separate workflow decisions. Do not revive the cancelled Debian-Recovered replication.

## Closeout result

Closeout is complete. Recovered material has recorded dispositions, Debian-Backup is retired, artifact decisions and exact cleanup effects are recorded, retained evidence is identified, and Debian4's final stopped state is documented. No retained artifact may be removed without a new explicit approval.
