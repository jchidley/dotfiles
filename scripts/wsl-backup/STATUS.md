# WSL backup and recovery status

This file records current operational truth and the evidence needed to continue safely. Git history retains superseded checkpoints.

## Current position

The Debian4 full-export implementation, production cold capture, real separate-distro recovery, and source integration are complete. Commit `285f28c` published the six-path implementation and evidence records after the canonical fast gate passed from an exact ext4 copy and pinned PSScriptAnalyzer 1.25.0 reported no findings.

The backup-assurance closeout is complete. The recovered-material package was reviewed, selected material was promoted with provenance and hash verification, Debian-Backup was retired, and approved superseded artifacts were removed. Optional replication is deferred. PostgreSQL activation and broader scheduler work remain outside this closeout.

See [`TASKS.md`](TASKS.md) for deferred work and the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) for the completed closeout record.

## Accepted full export and recovery

- Accepted generation: `C:/WSL-Backups/Debian4/full/20260909T170315Z-091d2190/`.
- Production cold clone `FullCapture-Debian4-091d2190`: removed after accepted archive and real-recovery evidence were retained.
- Production evidence: `C:/Users/jackc/.local/state/debian4-backup-assurance-20260909/production-cold-export-20260909T170310Z/`.
- Recovery distro and location: `Debian4-RecoveryTest-20260909A` at `C:/WSL-RecoveryTests/Debian4-RecoveryTest-20260909A`.
- Recovery evidence inside the retained stopped distro: `/var/tmp/debian4-real-recovery-20260909A/`.

The source VHDX remained exclusively locked while it was copied and exported from the retained cold clone. Source/cold-copy pre-registration hashes, schema-3 manifest, reviewed storage identity, archive checksum, gzip stream, full private listing, import, normal boot, system/home landmarks, ownership and modes, links, McFly integrity, scheduler observation, embedded Restic authentication, full-data check, and older-snapshot restore passed. The immutable capture manifest remains `restoreTested=false`; the separate retained real-recovery evidence establishes acceptance.

An external actor restarted Debian4 after the capture lock was released. Corrective shutdowns passed at the recorded checkpoint, but stopped state is volatile and must be rechecked before further work.

Exact ACL/user-xattr/capability comparison is not claimed because corresponding retained source examples were unavailable. Firewall changes and elevated offline-VHD isolation were rejected as unnecessary. These are not remaining acceptance gates.

## Closeout dispositions

The owner approved and the controller verified these recovered-material dispositions:

- promoted isolated snapshots to `/home/jack/recovered-projects/{energy-hub,life-fitness-console,octopus-tariff,whatsapp-sqlite-analysis}`;
- promoted celestial-navigation forms/source and woodworking scripts to `/home/jack/recovered-material/`, with provenance manifests;
- retained the divergent boat-data-platform snapshot for a future focused branch review, without changing the current checkout;
- retained research notes, Symphony prototypes, and private personal material only in the evidence workspace;
- required no promotion for public duplicate WSL Alpine/z2m-hub snapshots or the older public celnav snapshot.

`/home/jack/recovery/debian-final-recovery-20260909/DISPOSITIONS.md` records the per-group outcome. All promoted payloads matched their retained SHA-256 manifests; no recovered code or configuration was executed.

Debian-Backup's final non-booting inventory found the stopped registered clone redundant to the immutable image and completed evidence. With explicit approval, `Debian-Backup` was unregistered and `C:/WSL/Debian-Backup/` was removed. The immutable 149,704,146,944-byte August image remains present and read-only.

Approved cleanup also removed 21 disposable full-export/restore/capture registrations, all 13 `WslFullExportTests` directories, `Debian-Recovery-Tools`, superseded schema-1 generation `20260908T083849Z-7dd5c580`, the production cold-clone registration/VHDX, and the disposable forensic working VHDX. The accepted archive and required evidence were not removed.

## Retained state

Retain:

- accepted generation `20260909T170315Z-091d2190` and its production evidence;
- stopped `Debian4-RecoveryTest-20260909A`, its restored tree, and recovery evidence;
- the immutable read-only August forensic image and all evidence/report directories;
- the Windows and Debian4 recovered-material workspaces and promoted selections.

Debian4 and the retained recovery distro were stopped at final verification. Debian4's Linux backup timer remains enabled for its next natural start; no backup, retention, or prune operation ran during closeout. Optional Debian4 replication remains deferred and is not required.
