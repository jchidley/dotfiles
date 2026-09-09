# WSL backup and recovery status

This file records current operational truth and the evidence needed to continue safely. Git history retains superseded checkpoints.

## Current position

The Debian4 full-export implementation, production cold capture, real separate-distro recovery, and source integration are complete. Commit `285f28c` published the six-path implementation and evidence records after the canonical fast gate passed from an exact ext4 copy and pinned PSScriptAnalyzer 1.25.0 reported no findings.

The backup-assurance closeout is complete. The recovered-material package was reviewed, selected material was promoted with provenance and hash verification, Debian-Backup was retired, and approved superseded artifacts were removed. Optional replication is deferred. PostgreSQL activation and broader scheduler work remain outside this closeout.

See [`TASKS.md`](TASKS.md) for deferred work and the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) for the completed closeout record.

## Accepted full export and recovery

- Accepted generation: `C:/WSL-Backups/Debian4/full/20260909T170315Z-091d2190/`.
- Production cold clone `FullCapture-Debian4-091d2190`: removed after accepted archive and real-recovery evidence were retained.
- The generation's retained manifest records the accepted capture; the temporary Windows assurance directory was removed at closeout.
- Recovery test `Debian4-RecoveryTest-20260909A` completed successfully, then its registration, restored tree, and internal evidence were removed after the owner accepted the recorded result.

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

Debian-Backup's final non-booting inventory found the stopped registered clone redundant to the completed recovery. With explicit approval, `Debian-Backup` and its writable clone were removed. After the owner declared further forensic recovery exhausted, the immutable August image, raw carving/session recovery trees, final Windows recovery workspace, inspection evidence, and imported recovery-test distro were also removed.

Approved cleanup additionally removed 21 disposable full-export/restore/capture registrations, all `WslFullExportTests` artifacts, `Debian-Recovery-Tools`, superseded schema-1 generation `20260908T083849Z-7dd5c580`, the production cold clone, prior combined-backup evidence, temporary assurance records, empty recovery/capture directories, and dated backup test logs. The final Windows recovery workspace and its formerly locked empty root are gone. The accepted archive and Debian4 content were not removed.

## Retained state

Retain:

- accepted generation `20260909T170315Z-091d2190` and its manifest;
- Debian4's recovered-material workspace and promoted selections.

Debian4 was stopped at final verification. Its Linux backup timer remains enabled for its next natural start; no backup, retention, or prune operation ran during closeout. Optional Debian4 replication remains deferred and is not required.
