# Inspect the August Debian image without risking the source

This page records the completed built-in forensic pass and the partial specialist follow-up for Debian4 selection. The procedure below is historical, not an instruction to repeat either pass. Review the completed curation and import preview through the next-session entry point below; the [Debian4 plan](DEBIAN4-PLAN.md) owns sequencing and approval boundaries.

Keep the registered `Debian-Backup` distro stopped and preserve all source images, disposable copies, and partial evidence. Its purpose and lineage are represented by the immutable source and verified copy evidence; do not boot the registered clone for curation.

## Fixed inputs and boundaries

- Immutable input: `C:\Users\jackc\wsl-recovery-20260802\Debian-ext4-before-recovery.vhdx`
- Expected input SHA-256: `6d475115d9f214bcaf0093820e095b7989347e65119fcfcad1507999983747e3`
- Registered clone: `C:\WSL\Debian-Backup\ext4.vhdx`
- Existing raw-carving evidence: `C:\Users\jackc\wsl-recovery-20260802\pi-vhdx-carving\`
- Existing reconstructed-session evidence: `C:\Users\jackc\wsl-recovery-20260802\pi-session-recovery\`
- Prepared working copy: `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\working\ext4.vhdx`
- Prepared evidence directory: `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\evidence\`
- Copy manifest: `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\copy-manifest.json`

The prepared copy was completed at `2026-09-05T12:43:12Z`. Both source and copy matched the expected SHA-256, the copy is writable and unregistered/unmounted, the source remains read-only, and Debian-Backup remained stopped. This was the pre-attachment checkpoint; the subsequently approved execution results are recorded below.

The immutable input must remain read-only and must never be registered, repaired, compacted, optimized, or mounted read-write. Do not run `e2fsck -y`, journal replay, discard/TRIM, or any repair command against any evidence image. Recovered output must go to a separate evidence directory, never into the filesystem being examined.

## Execution result — 5 September 2026

The approved built-in pass completed against the prepared copy. Both image hashes matched before attachment; Hyper-V and Linux reported the observed disk read-only; it was absent from all visible mount tables; the full 1 TiB guest logical device was scanned; and cleanup detached the exact physical drive and VHDX. Final source hash and read-only state passed and Debian-Backup remained stopped. Evidence is under `evidence/offline-ext4-builtins-20260905T151200Z/`; its corrected `EVIDENCE-SHA256-v2.tsv` has 127 independently verified entries. A prior failed-closed sibling run stopped before filesystem readers and also cleaned up.

Filesystem-aware inspection found `/home/jack/.pi` absent from both live and deleted directory listings and no usable Pi journal path evidence. The logical scan retained 103,141 unique valid records, found guest offsets for 18 of the 20 genuine missing session IDs, and exposed a larger transcript/novelty review queue. See its `REPORT.md` for limitations: raw signatures include embedded JSON and do not by themselves prove recoverable session records.

The approved specialist follow-up was then attempted in a separate `Debian-Recovery-Tools` distro with pinned Debian packages ext4magic `0.3.2-15` and Sleuth Kit `4.12.1+dfsg-3`, against another hash-matched disposable copy. Sleuth Kit metadata passes completed but found no Pi path/inode. Broad ext4magic recovery produced 35,998 non-Pi files before WSL exhausted memory; no Pi path was recovered and broad magic mode was not run. The copy detached and final source/default/stop boundaries passed. Evidence is under `evidence/specialist-ext4magic-sleuthkit-20260905T162000Z/`. A materially different resource strategy is required before any broad retry.

## Reviewed operation (historical pre-execution record)

Tool discovery found WSL 2.7.12.0, Hyper-V `Mount-VHD -ReadOnly -NoDriveLetter`, e2fsprogs 1.47.2, util-linux 2.41, jq 1.7 and GNU coreutils 9.7. `ext4magic`, `extundelete`, TestDisk/PhotoRec and Sleuth Kit were absent. The reviewed method first opens only the prepared working VHDX through Hyper-V with `-ReadOnly -NoDriveLetter`, then exposes its resulting physical disk to WSL with `wsl.exe --mount <observed-physical-drive> --bare`. Before any filesystem reader runs, it must compare pre/post `lsblk` metadata, identify exactly one new disk, require the expected 1 TiB virtual size and ext4 signature, require Windows and Linux read-only state, and prove its major:minor identity is absent from all mount tables. Existing unmounted 1 TiB devices make size or an assumed `/dev/sdX` name insufficient.

On 5 September 2026, after this method and the broader recovery sequence were presented, the owner explicitly approved:

> Elevate as required to attach only `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\working\ext4.vhdx` through Hyper-V read-only/no-drive-letter and expose it to WSL as a bare, unmounted block device; identify it from observed metadata; verify it is read-only and not mounted; run the reviewed non-writable `blkid`, `dumpe2fs` and `debugfs` superblock, feature, live/deleted directory-entry, inode, extent, block and read-only journal inspection; recover selected Pi bytes only under the prepared `evidence` directory; stream-scan the read-only guest device for further Pi JSON records and transcripts while recording guest logical offsets; detach the working copy; and leave Debian-Backup stopped and both source distros unchanged.

The same approval covers analysis of the 21 session IDs absent from the current corpus and their 24 preserved variants, plus later use of reviewed `ext4magic` and Sleuth Kit commands in a separate recovery environment against additional disposable copies if the built-in pass leaves material gaps. Exact package source/version/install commands must be recorded before that limited installation; Debian-Backup must not be modified.

This approval excludes filesystem mounting, journal replay, `e2fsck`, repair, discard/TRIM, compaction, optimization, attachment of the immutable source, starting Debian-Backup, secret disclosure, Debian4 import, service/routing changes, backup initialization, and deletion of any source, working copy or evidence. Deleting the working or evidence directory is a later action.

## Next-session entry point — verified import and preserved evidence

1. Read `evidence/pi-corpus-curation-20260905T234252Z-v2/README.md`, `UNRESOLVED-GAPS.md`, and `IMPORT-PREVIEW.md`. Offline curation is complete for the 20 genuine missing sessions, 9,724 novelty signatures, and 51 bounded fragments. The first curation derivative is preserved as superseded; do not use its native destination preview.
2. Verify the complete curation package through its `EVIDENCE-SHA256-v2.tsv` and the sibling `pi-corpus-curation-20260905T234252Z-v2-EVIDENCE-SHA256-v2-verification.json`. Read `RECONSTRUCTION-ANNEX.md` for the additional 777-file older log-reconstruction tree, its zero annex-only forensic records, and the preserved v1 seal lineage. The independently checked 905-row native preview contains 860 baseline sessions, 27 baseline transcripts, and 18 additional self-contained candidates. All other variants, conflicts, partial sessions, marked transcript collections, and raw pools remain separate evidence.
3. Read `evidence/debian4-import-execution-20260906T112532Z/REPORT.md`, its 24-file seal and controller review: the approved import completed with all 905 native files and 2,826 archive payload files independently verified. The session-isolated `debian4-transfer-preparation-20260906T112532Z` launcher followed two preserved SIGHUP failures; do not rerun any prior launcher. The earlier preflight and preparations remain historical evidence. Follow [current tasks](../scripts/wsl-backup/TASKS.md) for the remaining migration work. Staging, fixtures, the imported archive and all sources remain protected; cleanup/retirement needs separate approval.
4. The specialist handoff remains sealed by its own `EVIDENCE-SHA256-v4.tsv` and sibling verification JSON. Historical v3 and its verification are unchanged; `handoff-before-v4/` preserves its two reports. These specialist manifests are distinct from the new curation package's manifest.
5. Do not repeat the completed attachment/full-device scan or broad specialist recovery unchanged. Any specialist retry requires a materially revised and reviewed resource/target strategy. Preserve every image, source distro, partial output, and completed evidence package.

## Historical execution procedure — not the current queue

1. **Recheck the boundary.** Record UTC time, WSL registration/state, immutable-source read-only attribute, source size, free space, tool versions, and the existing sidecar hash. Refuse if Debian-Backup is running or the source is writable. **Completed for the copy phase.**
2. **Create the disposable copy.** Copy the immutable VHDX to the approved working directory without changing the source. Hash the completed copy and refuse unless it matches the expected SHA-256. **Completed and recorded in `copy-manifest.json`.**
3. **Attach only the disposable copy.** Use a bare/unmounted attachment. Identify the ext4 block device from device metadata rather than assuming a device name. Confirm it is not mounted. If the chosen attachment mechanism cannot prevent automatic mounting or journal replay, stop and redesign; do not fall back to booting Debian-Backup.
4. **Capture filesystem evidence first.** Save read-only superblock, filesystem-feature, inode, deletion-time, and directory-entry reports. Capture the exact commands, versions, stdout/stderr, exit codes, and hashes of reports. Filesystem timestamps are evidence fields, not ordering truth.
5. **Recover selected Pi material.** Start with deleted inodes and directory entries plausibly associated with `/home/jack/.pi/agent/sessions` and `/home/jack/.pi/agent/session-transcripts`. Dump each candidate to a unique evidence path. Never overwrite a candidate with the same apparent name.
6. **Correlate with raw carving.** Compare recovered bytes with the existing 139,947-record scan, 816 recovered session IDs, the reconstructed 386 partial sessions, and Debian-Recovered's current Pi corpus. Use full-file SHA-256, session header ID/timestamp/cwd, record IDs, parent IDs, and record-sequence structure. Keep conflicting record IDs and partial variants as separate evidence.
7. **Write a collision ledger.** For every candidate record: evidence path, source image hash, tool and command, physical offset or inode where available, deletion/inode metadata, internal session metadata, byte count, SHA-256, comparison disposition, and uncertainty note. Do not synthesize missing original paths or timestamps.
8. **Validate without importing.** Parse every JSONL line, identify missing or synthetic headers, check internal session/header consistency, and report parent-chain gaps. A loadable synthetic file is a derivative and must point back to its exact recovered bytes.
9. **Detach and verify final state.** Detach the working copy, confirm it is no longer exposed as a block device, confirm Debian-Backup is still stopped, and recheck the immutable source's read-only attribute and hash. Preserve the working copy and evidence until review.

## Stop conditions

Stop without improvising if the source hash differs, the copy hash differs, Debian-Backup starts, the attachment auto-mounts read-write, a tool proposes repair or journal replay, output would land on the examined filesystem, free space becomes unsafe, or provenance cannot be recorded. Preserve completed logs and report the exact point of refusal.

## Completion evidence

The pass is complete only when the evidence directory contains a machine-readable manifest, command/tool log, collision ledger, hashes for every recovered file and report, validation summary, and final boundary checks. Import into Debian4 is a separate preview-and-approval operation governed by [the Debian4 plan](DEBIAN4-PLAN.md).
