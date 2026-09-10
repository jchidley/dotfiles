# WSL backup and recovery status

This file records current operational truth and the evidence needed to continue safely. Git history retains superseded checkpoints.

## Current position

The Debian4 full-export implementation, production cold capture, real separate-distro recovery, and source integration are complete. Commit `285f28c` published the six-path implementation and evidence records after the canonical fast gate passed from an exact ext4 copy and pinned PSScriptAnalyzer 1.25.0 reported no findings.

Debian-Backup recovery and Debian4 backup-assurance closeout are complete. Selected material was promoted with provenance and hash verification; Debian-Backup, exhausted forensic sources, recovery-test/fixture distros, and external recovery workspaces were removed by explicit approval. The accepted full archive remains.

Debian4 post-closeout reconciliation is complete. Wanted recovered material was promoted and verified; approved recovery workspaces and redundant staging were removed; promoted project trees remain inert; active documentation was reconciled; Terminal UI was accepted without cache cleanup; the canonical source gate passed; and the owner selected Debian4's running state. Post-promotion Restic coverage and a one-off Windows-side repository replica are verified. PostgreSQL activation and broader scheduler changes remain deferred, not incomplete closeout work. See [`TASKS.md`](TASKS.md) and the [Debian4 plan](../../docs/DEBIAN4-PLAN.md).

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

`/home/jack/recovery/debian-final-recovery-20260909/DISPOSITIONS.md` recorded the original per-group outcome. All promoted payloads matched their retained SHA-256 manifests; no recovered code or configuration was executed. During later approved reconciliation, the retained-only groups were promoted before this workspace was removed: the divergent boat snapshot to `/home/jack/recovered-projects/boat-data-platform-hourly-log`, and the archive-only boat service, research notes, Symphony prototypes, and private personal files to clearly named directories under `/home/jack/recovered-material/`. Their provenance manifests were copied with them and independent SHA-256 verification passed. The private destination is mode 700 with regular files mode 600.

Debian-Backup's final non-booting inventory found the stopped registered clone redundant to the completed recovery. With explicit approval, `Debian-Backup` and its writable clone were removed. After the owner declared further forensic recovery exhausted, the immutable August image, raw carving/session recovery trees, final Windows recovery workspace, inspection evidence, and imported recovery-test distro were also removed.

Approved cleanup additionally removed 21 disposable full-export/restore/capture registrations, all `WslFullExportTests` artifacts, `Debian-Recovery-Tools`, superseded schema-1 generation `20260908T083849Z-7dd5c580`, the production cold clone, prior combined-backup evidence, temporary assurance records, empty recovery/capture directories, and dated backup test logs. The final Windows recovery workspace and its formerly locked empty root are gone. The accepted archive was not removed. The later in-Debian4 cleanup removed only `/home/jack/recovery/debian-final-recovery-20260909` after its wanted retained-only material was promoted and verified.

## Retained state

Retain:

- accepted generation `20260909T170315Z-091d2190` and its manifest;
- Windows-side Restic replica `20260910T000023Z-6090f188` and its manifest;
- promoted inert project snapshots under `/home/jack/recovered-projects/`;
- promoted selected material under `/home/jack/recovered-material/`, including the verified PostgreSQL recovery package;
- the published private Pi recovery corpus under `/home/jack/.pi/agent/recovery/`.

## Continuation state

Read-only Windows checks after the session found:

- `main`, `HEAD`, and `origin/main` aligned at `e8b2b0f`; the worktree was clean and `git diff --check` passed;
- Debian4 running and LFS-Builder stopped; the actor that restarted Debian4 is unknown;
- no matching export, recovery-test, Debian-Backup, recovered-material, or Restic recovery-check process;
- the accepted generation present and every approved external recovery/fixture path absent;
- live Terminal `settings.json` reduced to five profiles, with no stale profile entry, while Terminal-owned `state.json` still listed 37 historical generated-profile GUIDs.

A reviewed read-only production inventory then established that scheduled snapshot `6090f188323a7267f1bca394b89459a75a31df03581fbb9b844a861299c34924` at `2026-09-10T01:00:23.876329397+01:00` contains the exact current entry counts and apparent file bytes for the retained recovery workspace (1,112 entries; 143,216,996 bytes), promoted projects (596 entries; 118,264,599 bytes), and promoted material (18 entries; 66,144 bytes). No manual backup is needed. The four promoted project directories remain inert file snapshots without `.git`.

With explicit approval, the complete encrypted Restic repository was copied while the Linux timer was temporarily stopped and the operation lock held. The verified replica is `C:/WSL-Backups/Debian4/restic/20260910T000023Z-6090f188/`: repository ID `fad9e4c059250bf3d0d22ab90018ba599d09b57deaed944c4e0b1277c7c81dac`, 495 files, 1,550,057,335 apparent bytes. The source/destination counts and bytes matched, the pinned snapshot was present, and `restic check` reported no errors. The timer was restored enabled and active, its service was idle, and Debian4 remained running. This replica protects against loss of the VHDX but remains on the same physical Windows disk.

The 143 MB final-recovery workspace was removed after the later promotions and independent verification. A final focused classification retained the 2.70 GB published private Pi recovery corpus under `.pi/agent/recovery`, promoted the verified PostgreSQL package to `/home/jack/recovered-material/postgresql-boatdata`, and removed 3,266,927,767 apparent bytes of explicitly approved redundant import staging, disposable import fixtures/rehearsal data, the public-duplicate z2m-hub source snapshot, and the superseded PostgreSQL source directory. Independent SHA-256 verification of the promoted PostgreSQL package passed; its directories are mode 700 and files mode 600. Unrelated application/tool directories with recovery-like names were not changed.

The focused Windows Terminal test and PowerShell parse check passed before commit `41ff4f5`. The owner restarted Terminal and found its UI correct, so the 37 historical GUIDs in Terminal-owned `state.json` require no cleanup. Active READMEs and historical-result pointers were reconciled against the canonical records. The canonical fast lane then passed from an exact disposable ext4 copy of the current worktree; this included pinned PSScriptAnalyzer 1.25.0. The owner selected Debian4's final running state; the timer is enabled and active, its service is idle, and Debian4 is running. Any further Debian4 content deletion, production backup/status operation, source stop/restart, Terminal state-file cleanup, or retained archive/Restic-replica removal requires its applicable review and approval.
