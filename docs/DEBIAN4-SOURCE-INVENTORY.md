# Debian4 source inventory

This reference records dated source-selection snapshots and the later verified Pi file import. It supplements the active [Debian4 plan](DEBIAN4-PLAN.md); it is not an authorization or a migration manifest.

## Latest migration pointer — 7 September 2026

The [current tasks](../scripts/wsl-backup/TASKS.md) and [`STATUS.md`](../scripts/wsl-backup/STATUS.md) supersede the earlier missing-tool, unexecuted credential/history-transfer, unresolved repository, and incomplete-backup statements below. Selected data, AK routing, required bootstrap changes, full-export recovery assurance, and source retirement subsequently completed. These dated inventories are provenance, not a current transfer manifest or permission to replay work.

## Verified Pi import — 6 September 2026, 11:49 UTC

`debian4-import-execution-20260906T112532Z/REPORT.md` under the inspection evidence root records the completed approved import: 905 native files (878 sessions and 27 transcripts), plus the separate 2,826-file evidence payload archive. All 3,731 payload files were published without skips/overwrites and independently verified, including permissions and archive completeness. Staging, fixtures and all source evidence remain retained; no credentials, services, routing or default distro were changed. The 24-file execution seal and controller review passed. Pi was not opened for validation. The source/target tables below retain their dated pre-import observations; they are not the current target inventory.

## Runtime and image boundary — 5 September 2026, 11:55 UTC

| Item | Verified state |
|---|---|
| Windows default distro | Debian-Recovered |
| Debian-Recovered | Running; registered default UID 1000 |
| Debian4 | Running; registered default UID 1000 |
| Debian-Backup | Stopped; registered at `C:\WSL\Debian-Backup`; default UID 0 |
| Immutable August VHDX | 149,704,146,944 bytes; Windows `ReadOnly` attribute set |
| Registered Debian-Backup VHDX | 149,704,146,944 bytes; writable file; stopped distro |

The immutable source sidecar records SHA-256 `6d475115d9f214bcaf0093820e095b7989347e65119fcfcad1507999983747e3`. Prior evidence records that the staged clone matched before registration. A fresh hash of the registered clone could not be obtained because WSL retains an open handle even while the distro is stopped. No broader WSL shutdown, detach, start, or unregister was attempted. Current post-registration byte identity is therefore unverified and is not needed for the safer disposable-copy procedure in [the inspection guide](DEBIAN-BACKUP-INSPECTION.md).

At `2026-09-05T12:43:12Z`, an approved unregistered working copy was completed at `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\working\ext4.vhdx`. Source and copy both matched the expected SHA-256 and length. The source remained read-only; the working copy is writable, unmounted, and unregistered. `copy-manifest.json` beside it records the operation. Debian-Backup remained stopped.

## Existing August recovery evidence

| Evidence | Verified summary |
|---|---|
| `pi-session-recovery` | 777 files, 175,644,957 bytes; 386 reconstructed session files; 5,442 deduplicated JSON records; 8 original and 378 explicitly synthetic headers; validation records zero malformed JSON lines |
| `pi-vhdx-carving` | 1,406 files, 1,462,404,325 bytes; complete 149,704,146,944-byte raw scan; 139,947 unique records, 125,088 unique record IDs, and 3,715 conflicting record IDs |
| Carved session manifest | 1,450 variants representing 816 session IDs; 1,424 entries have `/home/jack...` cwd; 61 are marked duplicate |
| Debian-Recovered support evidence | 897 files, 484,750,109 bytes; scripts, logs, staging reports, merge reports, repository bundles, and validation records |
| Recovered live merge | Staged 812 best carved sessions; merge reported 278 added, 63 synthetic replacements, 5 longer replacements, 227 identical, and 239 live files retained |
| Post-merge validation checkpoint | 845 session files, 136,638 JSON lines, zero malformed or empty files; one file lacked a session header |

The current Debian-Recovered count is now 860 session JSONL files and 27 transcript files. The difference from the 845-file 3 August checkpoint is later live activity, not by itself evidence of a recovery mismatch.

At `2026-09-05T13:05:19Z`, the current mixed Debian-Recovered Pi corpus was independently preserved under `debian-backup-inspection-20260905T120500Z/evidence/debian-recovered-current-pi-20260905T130519Z/`. GNU tar completed without error using system atime preservation; the archive contains all 860 session files and 27 transcripts, is 547,072,000 bytes, and has SHA-256 `a4e557681fde0a278599b870136fcc7ea2d9d8ed81393f0609aaa534c0708c9f`. An extracted evidence tree, per-file hashes, command log, and provisional provenance ledgers are retained beside it. All 140,212 session records parse as JSON; 135,748 records match physical-carving record hashes and 4,339 have internal timestamps after the retained recovery checkpoint. These counts do not make the current files original: the ledger explicitly distinguishes merge products, carved matches, post-checkpoint candidates, and unresolved origins.

The same evidence operation then reconciled the current corpus with all 234 existing Restic snapshots, both validated 24 August WSL exports, six commits of `agent-state-backup`, the 68-file merge backup, and the physical carved-session manifest. Restic was read with `--no-lock --no-cache`; its history starts on 17 August, after the original recovery, and exposes four observed Pi states containing 856, 858, 859, and 860 sessions. One representative of each state was restored only into evidence. Neither Restic nor the two exports contains a session ID or full-file variant absent from the current corpus. Git history contributes three session IDs and seven file variants absent from current; the merge backup contributes two absent IDs and 68 old variants. Across all sources there are 855 session IDs, of which 21 are absent from current; all 21 occur in the physical carving. Twenty-four distinct carved variants for those IDs are now independently retained under `additional-session-candidates/physical-carved-v2-by-hash/`, with hashes, source offsets, paths, and provenance. The first filename-based copy attempt failed closed after seven files because retained carved filenames do not uniformly use manifest offsets; that partial output and its failure record were preserved, and the completed second pass matched candidates by SHA-256. `EVIDENCE-SHA256-v2.tsv` seals 7,291 evidence files. At that checkpoint, offline ext4 metadata/journal inspection was pending; its completed results and subsequent curation are recorded below. The owner subsequently approved analysis of the 21 missing IDs, the reviewed fail-closed read-only/bare attachment and built-in ext4/logical-scan pass, and—only if gaps remain—a separately designed `ext4magic` and Sleuth Kit pass in a separate recovery environment against additional disposable copies. No Debian4 import, source alteration, filesystem mount, repair, replay, discard or deletion was authorized.

Filesystem timestamps do not establish original chronology. Existing evidence preserves raw physical hits, content conflicts, internal Pi IDs/timestamps/cwd values, and the destructive-operation attribution.

The approved filesystem-aware pass subsequently completed. Analysis corrected the nominal 21 missing IDs to 20 genuine UUID sessions plus one `uuid` example artifact: 16 groups have only structurally complete candidates, two have complete physical candidates plus partial/synthetic merge variants, two event-stream sessions are partial-only, and no conflicting record IDs were found. Three March files have byte-identical Git-history evidence; merge-backup variants for two July sessions are synthetic and weaker than the carved headers. Separately marked readable derivatives are under `additional-session-candidates/analysis-derivatives-v2/`.

The built-in pass found that the rewritten `/home/jack` has no `.pi` entry and exposed no deleted Pi inode/path or useful journal path evidence. Its complete logical-device scan retained 103,141 unique valid records and guest offsets for 18 of the 20 genuine missing IDs; the two absent logical headers remain in physical carving. Raw-signature novelty and transcript records require curation because embedded JSON can satisfy the signature. A pinned ext4magic/Sleuth Kit follow-up in a separate recovery distro added no Pi bytes: Sleuth Kit found no Pi path/inode, and broad ext4magic recovery stopped on WSL memory exhaustion after 35,998 non-Pi files. All images detached, the immutable hash remained correct, Debian-Recovered remained default, and Debian-Backup remained stopped. See the evidence-local reports; do not retry broad specialist recovery without a materially revised resource strategy.

## Offline curation result — 6 September 2026 UTC

The final bounded curation package is `debian-backup-inspection-20260905T120500Z/evidence/pi-corpus-curation-20260905T234252Z-v2/`. It preserves 1,748 distinct exact-byte source files for all 9,200 ledger instances, both raw record pools and offset ledgers, all 51 selected fragment byte ranges, and separately marked transcript derivatives. The previous first-pass derivative is retained as superseded after a cwd destination-encoding correction.

The 20 genuine missing sessions yield 18 self-contained native candidates and two partial-only evidence sessions. The 181 UUID-shaped transcript IDs yield 177 schema-valid groups containing 9,579 records, plus four UUIDs represented only by incomplete metadata; one placeholder example is excluded. Independent comparison corroborates 6,636 transcript records against native visible content and 5,694 against branch ancestry as well. The remaining 2,943 have explicit text/cwd/missing-entry discrepancies. Corpus-wide validation retains 240 record-ID conflict groups without overwriting any version. All 9,724 novelty signatures and 51 fragments have dispositions; none of the fragments supplies a complete native prefix. One historical physical-ledger size mismatch is recorded separately while its content hash remains correct.

Read the package's `README.md`, `UNRESOLVED-GAPS.md`, `IMPORT-PREVIEW.md`, and `independent-verification.json`; its final seal is `EVIDENCE-SHA256-v2.tsv` with a sibling verification JSON. A separate 777-file annex preserves the older log-reconstruction tree: all 4,842 distinct forensic records match primary variants or protected raw pools, with no new original header IDs; it does not change the native selection. V1 and its original report bytes remain preserved. The 905-row native preview covers the frozen 860-session/27-transcript baseline and 18 additional candidates. The separate evidence archive retains every uncertain variant. During that offline curation, no import, WSL launch, production query, credential operation, or image attachment occurred. The later approved preflight under `debian4-import-preflight-20260906T002855Z/` verified all 887 live source files still match the frozen baseline, Debian4 still has no session/transcript files, all 905 native destinations and the archive root are absent, and guest/host capacity is sufficient. Only Debian-Recovered and Debian4 were started for that inspection; all distros were stopped at its final check. The preview needs no delta/conflict revision. Transfer preparation subsequently completed under `debian4-transfer-preparation-20260906T005124Z/`: 20 generated-data ext4 scenarios, seven refresh-guard tests, three detected semantic faults, and detached-job exit-marker checks passed. The fixed 905-native/2,826-archive plan retains independent staging and requires fresh checks plus final owner approval. Only Debian4 was entered for disposable testing; the actual Pi destinations and real import staging remained absent. No actual import occurred during preparation; the later completed operation is recorded above.

## Selectable source/target snapshot — prior live inventory

### Pi and shell history

| Data | Debian-Recovered | Debian4 | Selection status |
|---|---:|---:|---|
| Pi session JSONL files | 860 | 0 | Wanted; compare with August variants before import |
| Pi transcript files | 27 | 0 | Wanted; preserve exact cwd/path and collisions |
| McFly live database | 73,728 bytes, mode 600 | Absent | Likely wanted; inspect schema/content only in an approved merge preparation |
| McFly recovery copy | 73,728 bytes, mode 600 | Absent | Compare consistently with live DB; do not assume equality from size |
| Bash history | 3,076 bytes, mode 600 | 512 bytes, mode 600 | Deliberate merge required; never overwrite either input |

No history contents were printed. McFly row-level comparison and Bash-history merge policy remain open.

### Repositories

Read-only metadata inspection found these Debian-Recovered worktrees:

| Path | Commit | Porcelain entries |
|---|---|---:|
| `~/git/agent-skills` | `766d92114899d97497d7ca37ab73598c3a9c7edf` | 0 |
| `~/git/agent-state-backup` | `a59a6aac357ba2bd69424ddd7f80fac637fff828` | 0 |
| `~/git/ak` | `7c53208f1b48109d8db1b6ed191131d00872c18f` | 1 |
| `~/git/mkdocs-material-test` | `54462cfa0fac2f80ddfec0e09a91fdbc6af68bef` | 0 |
| `~/git/symphony` | `8001b52e3062495a16e520e4ceaf8f9de868c4d0` | 0 |
| `~/boat-data-platform` | `d18e28dfa02cde135a5536bbb5dc85d6632ad7db` | 0 |
| `~/tools` | `7e65d2b0fc1d348e6519eaeee66765dba630136f` | 0 |

Debian4 currently has clean `agent-skills` (`6725342`), `ak` (`7c53208`), and `tools` (`42c1089`) worktrees. Repository selection must compare upstream state plus uncommitted, unpushed, ignored, local-only, and deleted material; a clean porcelain count is not proof that no unique refs or ignored files exist. The one dirty `ak` entry remains intentionally unread and unresolved.

### Credentials, database, and backups

- Debian-Recovered remains authoritative for SSH and existing AK values. No value or private-key content was read.
- Debian4's new passphrase-protected GPG identity and selected direct re-encryption remain unexecuted.
- PostgreSQL remains undecided; no service or database content was inspected in this continuation.
- Existing Restic histories remain source-owned. No repository, password, marker, snapshot, or scheduling state was read or changed.

## Historical Debian4 capability gaps — before subsequent bootstrap completion

Debian4 still lacks `gh`, `delta`, `nvim`, `uv`, `uvx`, `rg`, `fd`, and `hx` on its native PATH. Its deployed `~/bin/web-search` still calls the absent legacy `~/.pi/agent/skills/web-search/web-search`, and its deployed Pi guidance still contains `Autonomous Completion`. Repository source now corrects both, but no chezmoi apply was performed. No Pi or McFly data is present.

Repository-only fixes in this continuation also make a fresh shell create a missing mode-600 Bash history file before McFly initialization, remove the known ShellCheck SC2015 construct, and reconcile the committed Pi `AGENTS.md` template with current machine guidance. These changes have passed the retained bootstrap test but have not been deployed to Debian4.
