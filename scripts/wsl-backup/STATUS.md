# WSL backup and recovery status

This file records current operational truth and the evidence needed to continue safely. Git history retains superseded checkpoints.

## Current position

The Debian4 full-export implementation, production cold capture, real separate-distro recovery, and source integration are complete. Commit `285f28c` published the six-path implementation and evidence records after the canonical fast gate passed from an exact ext4 copy and pinned PSScriptAnalyzer 1.25.0 reported no findings.

The remaining closeout starts with review of `/home/jack/recovery/debian-final-recovery-20260909`, followed by separately approved Debian-Backup retirement and artifact cleanup decisions. Optional replication is deferred. PostgreSQL activation and broader scheduler work are outside this closeout.

The current documentation reconciliation is intentionally unpublished pending review. See [`TASKS.md`](TASKS.md) for the exact remaining sequence and the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) for approval boundaries.

## Accepted full export and recovery

- Accepted generation: `C:/WSL-Backups/Debian4/full/20260909T170315Z-091d2190/`.
- Retained production clone: `FullCapture-Debian4-091d2190`.
- Production evidence: `C:/Users/jackc/.local/state/debian4-backup-assurance-20260909/production-cold-export-20260909T170310Z/`.
- Recovery distro and location: `Debian4-RecoveryTest-20260909A` at `C:/WSL-RecoveryTests/Debian4-RecoveryTest-20260909A`.
- Recovery evidence inside the retained stopped distro: `/var/tmp/debian4-real-recovery-20260909A/`.

The source VHDX remained exclusively locked while it was copied and exported from the retained cold clone. Source/cold-copy pre-registration hashes, schema-3 manifest, reviewed storage identity, archive checksum, gzip stream, full private listing, import, normal boot, system/home landmarks, ownership and modes, links, McFly integrity, scheduler observation, embedded Restic authentication, full-data check, and older-snapshot restore passed. The immutable capture manifest remains `restoreTested=false`; the separate retained real-recovery evidence establishes acceptance.

An external actor restarted Debian4 after the capture lock was released. Corrective shutdowns passed at the recorded checkpoint, but stopped state is volatile and must be rechecked before further work.

Exact ACL/user-xattr/capability comparison is not claimed because corresponding retained source examples were unavailable. Firewall changes and elevated offline-VHD isolation were rejected as unnecessary. These are not remaining acceptance gates.

## Retained state and preservation holds

Preserve until separately dispositioned:

- Debian-Backup and the immutable forensic image;
- the accepted production archive and retained cold clone;
- `Debian4-RecoveryTest-20260909A`, its restored tree, and recovery evidence;
- failed generations, fixture/capture registrations, and test evidence;
- `/home/jack/recovery/debian-final-recovery-20260909` and its source evidence.

Do not unregister a distro or delete evidence without explicit owner approval. Starting Debian4 also requires separate approval; its enabled Linux timer may run naturally unless the approved operation explicitly controls that boundary. Do not run backup, retention, prune, production export, or recovery verification merely to inspect closeout state.

## Unverified and unresolved

- The contents of `/home/jack/recovery/debian-final-recovery-20260909` have not been reviewed or promoted.
- Debian-Backup has not received its final retirement inventory, and retirement is undecided.
- Retention versus cleanup is undecided for recovery, fixture, failed-generation, clone, restored-tree, and evidence artifacts.
- Optional Debian4 replication remains deferred, not required.
- Current distro state, matching processes, branch alignment, and dirty paths are volatile and must be checked at the start of continuation work.
