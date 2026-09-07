# WSL backup and recovery status

## Current direction

**Source review checkpoint — 7 September 2026:** Windows dotfiles now includes Debian4's committed bootstrap/guidance through `fc8b1e3`, with its Windows work preserved separately. Terminal assets are locally committed at `efe87ba`. The [Debian4 backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) identifies stale source/restore assumptions, unsafe unchecked cleanup, unproven first-boot isolation, journal identity concerns and missing behavioral tests. The exporter/password candidate remains unaccepted and undeployed. Its exact-source canonical fast lane passed through the managed Node job: 44 home, 38 shadow, 115 state-adapter, 55 consent, 78 migration and 29 system assertions; 25 retained mutations; PSScriptAnalyzer 1.25.0 clean across 20 paths. Setup/CLI tests and 30 Linux scheduler assertions also passed. The earlier foreground call timed out with no retained result; no matching processes remained before the managed rerun. Evidence is under Windows `~/.local/state/migration-closeout-20260907/dotfiles-fast-job/`. These fixture/static gates do not resolve the documented runtime safety defects or prove real import isolation. Storage/password choices remain deferred. Later tasks record Debian4 as the Windows default and the AK target; older default-distro statements below are historical, not instructions to reverse that cutover. No new credential, production-state or source-retirement check was performed here.

The [Debian4 plan](../../docs/DEBIAN4-PLAN.md) is the sole active sequence. Debian4 is the clean successor. Debian-Recovered and Debian-Backup are temporary extraction/verification sources and are intended for eventual removal only after useful current/deleted data reaches Debian4 and independent recovery exists. Debian-Backup was rebuilt, without booting, as a stopped writable clone of the read-only August forensic VHDX; its staged hash matched the preserved source. The 7 September tasks record Debian4 as the Windows default distro. Debian2 and Debian3 are retired.

Debian4's backup units are installed but disabled/inactive; no password or Restic repository was initialized, and installed defaults still require review. The unfinished exporter/password-test candidate remains uncommitted and is not deployment-ready. Linux/systemd ownership of routine scheduling remains the accepted architecture.

The bounded forensic operation is specified in [`DEBIAN-BACKUP-INSPECTION.md`](../../docs/DEBIAN-BACKUP-INSPECTION.md), and current nonsecret selection evidence is recorded in [`DEBIAN4-SOURCE-INVENTORY.md`](../../docs/DEBIAN4-SOURCE-INVENTORY.md). The approved built-in pass completed on 5 September: both source/copy hashes passed; only the prepared copy was attached read-only/no-drive-letter and exposed bare; Windows/Linux read-only and all-mount-table checks passed; the full 1 TiB logical device was scanned; exact detach/final boundaries passed; and Debian-Backup remained stopped. The ext4 tree contained no `.pi` directory or recoverable deleted path/journal entry. Evidence is under `offline-ext4-builtins-20260905T151200Z`.

The nominal 21 missing IDs are 20 genuine sessions plus one synthetic `uuid` example. Sixteen groups have only structurally complete candidates, two have complete physical candidates plus weaker partial/synthetic merge variants, two event-stream sessions are partial-only, and three March originals have byte-identical Git-history evidence. The logical scan found offsets for 18 genuine missing headers and retained substantial record/transcript novelty for review.

The separately approved specialist follow-up used pinned ext4magic/Sleuth Kit packages in a stopped separate recovery distro and another hash-matched disposable copy. Sleuth Kit found no Pi path/inode. Broad ext4magic recovered 35,998 non-Pi files before WSL memory exhaustion and added no Pi bytes; broad magic mode was not run. Cleanup detached the image, the immutable source hash passed, Debian-Recovered remained default, and Debian-Backup remained stopped. Do not retry the broad mode without a materially revised resource strategy. Preserve all partial evidence and working copies.

Offline curation completed on 6 September UTC under `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\evidence\pi-corpus-curation-20260905T234252Z-v2\`. It verifies 9,200 source instances and preserves 1,748 distinct exact-byte files plus both raw record pools and their offset ledgers. All 9,724 novelty signatures and 51 bounded fragments have explicit dispositions. The native preview contains 18 additional self-contained candidates alongside 860 baseline sessions and 27 baseline transcripts; two partial sessions remain evidence-only. Marked transcript derivatives contain 9,579 records across 177 sessions, with 6,636 independently corroborated against native visible content and 5,694 also supported by branch ancestry. The gap report preserves 2,943 unconfirmed transcript records, 240 corpus-wide record-ID conflict groups, unmerged messages, and incomplete fragments; no uncertain content was merged into native history. Eleven focused tests and a separately implemented verifier passed. The separately preserved older reconstruction annex adds 777 exact-byte files; all 4,842 distinct forensic records are already represented in the primary variants or protected raw pools, so the native selection is unchanged. Use the final package's `EVIDENCE-SHA256-v2.tsv` and sibling seal-verification JSON; v1 and its original reports remain preserved. The first derivative pass is preserved as superseded after a destination-encoding correction. No WSL operation or import occurred during curation; the later approved preflight is recorded next.

The approved live-source/target preflight passed on 6 September UTC under `debian4-import-preflight-20260906T002855Z/` in the same evidence root. All 887 live source files match the frozen baseline; Debian4 has zero session/transcript files; all 905 native destinations and the archive root are absent; no conflicts or source delta were found. The unchanged proposal totals 3,241,318,900 bytes, with sufficient guest and host capacity for a two-copy staging allowance. Only Debian-Recovered and Debian4 were started for read-only content inspection; no Pi data or service configuration was changed. All distros were stopped at the final Windows-side check, with Debian-Recovered still default and Debian-Backup/Recovery-Tools never started. The preflight report and seal preserve the evidence. The subsequently approved transfer preparation is recorded next; preflight approval did not authorize import.

Transfer preparation completed on 6 September UTC under `debian4-transfer-preparation-20260906T005124Z/` in the same evidence root. Its fixed plan (SHA-256 `9f94ebfdd84b9a6cff29445c49519ff1eaddbc7853d00d5aba9f72cd11d32a91`) contains the unchanged 905 native files and 2,826 archive payload files. Twenty generated-data ext4 scenarios, seven refresh-guard tests, three directly detected semantic faults, and detached-job success/failure status checks passed. The importer retains independent staging, publishes exclusively without overwrites, preserves existing metadata, journals partial output, and runs a separately implemented destination verifier. Rollback preview deletes nothing; staging/target removal needs separate approval. Only Debian4 was entered for these disposable tests. The real native roots, archive and import staging remained absent; all distros were stopped at the final Windows check, and Debian-Recovered remained default. Read the preparation's sealed `REPORT.md` and `IMPORT-PROCEDURE.md` for exact effects and limitations. Its `EVIDENCE-SHA256-v1.tsv` has SHA-256 `aef23f1072580c23cafd65c0bf593d721d27d78635ab41f8b97b96c899f376e2`; separate verification checked all 50 files with zero failures. Final owner approval is still required before fresh narrow checks and the actual import; no import or cleanup has occurred.

The owner then approved the fixed import. The single `debian4-import-execution-20260906T005124Z` attempt captured fresh inventories and recorded detached PID 297, but no worker startup log, exit marker or verified import result appeared. A subsequent Windows-only observation showed all distros stopped, with Debian-Recovered still default. The import is blocked, not accepted complete; post-failure target/staging contents were not inspected. No duplicate launch, cleanup or termination occurred. Preserve the execution report and all possible output; diagnose and review/test a revised transport before a separately approved retry. This supersedes the preceding pending-initial-approval checkpoint.

The owner then authorized root diagnosis, correction and continuation. Diagnostic probes tied the launch failures to SIGHUP on terminal-session teardown. The first corrected `20260906T111631Z` attempt protected/acknowledged Bash, but Node died with Hangup (exit 129); a bounded metadata check found native roots, archive and that staging absent. Both failed executions and preparations remain preserved. The successful `debian4-transfer-preparation-20260906T112532Z` version also enters a separate session before acknowledgement and checks no controlling terminal in Bash and Node. Nine actual-Node launch cases passed, including six generated-data imports with separate verification. Its 101-file preparation seal is `52af57ff365d217f6fcc050bb844f1bafe0f173e0e4f70afac96c53ef8d5d53e`.

**Pi file import completed — 6 September 2026, 11:49 UTC:** `debian4-import-execution-20260906T112532Z` published all 905 native files (878 sessions and 27 transcripts) plus 2,826 archive payload files: 3,731 files, 3,241,318,900 bytes, zero skips or overwrites. The separate verifier checked every payload, exact archive contents, permissions and completion marker with zero failures. Fresh checks accepted all 887 source files and 905 destinations. The 24-file execution seal is `998ade22886a886687e652e1d71fb24972db4295e377da78b55b347487c5bab9`; independent seal verification and controller review passed. Native data is under `/home/jack/.pi/agent/{sessions,session-transcripts}/`; the separate archive is under `recovery/pi-corpus-curation-20260905T234252Z-v2/`. Independent staging/journals remain at `/home/jack/.local/state/pi-recovery-import/20260906T112532Z/`. All sources, failed attempts and fixtures remain retained. Only approved temporary publishing links/incomplete marker were removed. Pi was not loaded; verification is file-level, not whole-migration completion. After one disclosed read-only progress diagnosis during the longer real transfer, execution completed normally. All distros were stopped naturally at final review; Debian-Recovered remained default, with no credential, service, scheduler, backup, routing or image change. Cleanup/retirement and remaining migration work need their own scope/approval. This completion supersedes the preceding blocked checkpoints.

**Selective home-data migration — 7 September 2026:** a complete read-only `/home/jack` hash inventory identified unique user data versus reproducible caches and duplicate clean checkouts. Preservation-first transfer installed Debian-Recovered's exact clean boat-data-platform tree at `d18e28d` (19 commits ahead of cached upstream) and heatpump-analysis tree at `6d56d8d`, with verified Git bundles and source tarballs retained on Windows. Debian4 received the exact uncommitted `ak` `services/spider.yaml` delta, an integrity-checked McFly merge (211 commands), a deduplicated Bash-history merge, exact passphrase-protected SSH identity bytes plus merged known-hosts, 39 search-benchmark files, four tmp files and the download ledger. Existing target state was retained under `~/.local/state/debian4-superset-migration/`. Debian4's 14 expected AK service files all decrypt with its separate GPG identity; approved Windows/WSL routing now targets Debian4 and all 14 managed lookups pass. Equality to the locked source and SSH key use remain interactive checks. Large remaining byte differences are clean duplicate/publication checkouts, dependencies, caches, old GPG runtime/keyring state and other reproducible material, not selected for wholesale copy. Evidence is under `C:\Users\jackc\wsl-recovery-20260802\debian4-superset-migration-20260907T000000Z` and `home-jack-comparison-20260906T230000Z`.

Everything below is dated migration, comparison, restore, and source-integration evidence. It is not the current execution queue. The historical [Debian3 comparison](../../docs/DEBIAN3-RECOVERED-COMPARISON.md) records selected provenance before removal.

## Prior recovery inspection — 5 September 2026

This section preserves dated operational evidence; the phase reports below are historical source/integration records, not current deployment instructions. See [`TASKS.md`](TASKS.md) for incomplete work and the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) for the active sequence and approval gates.

**Historical bottom line at that checkpoint:** the bounded migration/recovery inspection completed, retained Restic restore evidence and the two boat-database comparisons passed, while independent password recovery and a validated Debian3 whole-distro generation had not completed. Debian3 was later retired by explicit owner authorization. No scheduler cutover needs to be replayed.

### Initial read-only inventory

Read-only inspection at `2026-09-04T23:48:13Z` (5 September local time) found:

- Windows checkout: `a4b6246ded8d6efb4ff50a15c830d685497dae99`; no tracked changes before this documentation update. The untracked `NEXT-SESSION.md` is relay-owned and was not changed.
- At this initial inventory, Debian3 and Debian-Backup were stopped; neither had been started by this inspection. Debian-Recovered was running with systemd.
- No `WSL Home Restic - *` Windows tasks exist. Debian-Recovered's `wsl-home-scheduler.timer` is disabled/inactive and its scheduler service is inactive.
- Debian-Recovered PostgreSQL 17 was online on port 5432. Database comparison was performed in the later privileged inspection below.
- The default Windows export directory contains two August Debian-Recovered archives and manifests, but no Debian3 generation. The inspected `20260824T002316Z` manifest records a successful historical import validation; its archive hash and restore were not revalidated now. Other storage locations were not searched.
- Debian-Recovered's clean chezmoi checkout is at `05710eae9b09e645f7ab63cb211c740f1aa75c8f`, not the Windows source commit. It does not contain the Windows commit object, so a cross-commit diff was unavailable. No checkout was synchronized or deployed.

### Authorized Debian3 startup and follow-up inspection

The owner subsequently approved starting Debian3 for this bounded inspection. At `2026-09-04T23:51:17Z`, Debian3 was running with systemd, its backup timer enabled/active, and its scheduler service inactive with `Result=success` and `ExecMainStatus=0`. The timer's reported last trigger was 5 September at 00:29:32 BST; this is not proof of a fresh snapshot. PostgreSQL 17 was online on port 5433. No scheduler configuration was changed or backup command manually invoked; enabled services may run naturally after startup.

Accessible follow-up checks verified:

- SSH private-key ownership `1000:1000` and mode `600`; 860 Pi session files and 27 files under `~/.pi/agent/session-transcripts`.
- McFly recovery SQLite integrity `ok`, using a read-only immutable connection.
- Retained PostgreSQL dump checksums passed for `roles.sql`, `boatdata_direct.dump`, and `boatdata_staging.dump`. This verifies retained-file consistency, not current database equality or a new restore.
- `/etc/restic/home.password.bitwarden-confirmed` is absent; its parent directory is traversable, so this is not an access-denied inference. No password contents were read.
- Installed `backup-wsl-home` and `validate-wsl-system-restore` are present; `/home/jack/boat-data-platform/.git` is absent, confirming a legacy-validator incompatibility.
- Debian3's clean chezmoi checkout is at `ad8ec45cd7c82a7b3e37ec43cba17b58b28fb3cc`. Configured nonsecret backup values identify host `Debian3`, source `/home/jack`, repository `/var/lib/restic/home`, and logs `/var/log/restic-home`.

Root-only backup logs/repository state and the system journal could not be read as `jack`; lack of visible entries was not evidence of missing backups. The owner then approved the privileged read-only inspection below.

### Privileged backup evidence and database comparison

At `2026-09-04T23:54:19Z`, approved root-only record inspection confirmed:

- Scheduler state schema 1 with `last_retention_success_epoch=1788564558`.
- Backup log: Debian3 snapshot `30a93991` saved, operation completed at 00:29:28 BST on 5 September; retention completed at 00:29:30.
- Structural check completed without errors at 00:30:36. Three retained restore logs record successful 1.028 GiB restores, the last completed at 00:32:15. No new backup, check, retention, or restore was invoked during inspection.
- System journal corroborates the successful scheduler run and its snapshot-health result at that time. These are retained records, not a fresh repository-health check or an all-history data verification.
- Escrow marker remains absent. No password contents were read.

At `23:55:01Z` (Debian-Recovered) and `23:55:10Z` (Debian3), read-only PostgreSQL comparison found matching application table content and sequence state:

| Database | Tables | Nonempty | Rows | Table-data SHA-256, equal on both distros |
|---|---:|---:|---:|---|
| `boatdata_direct` | 66 | 27 | 112,996 | `e446043828024c64f7338d10e6502f6531da2bf1b0ec3790b101876c9565d328` |
| `boatdata_staging` | 106 | 41 | 121,623 | `71515539433820479b329bab2e298a0aee1035bb2565d63d68b3ced0a7ea4527` |

Each database's table reads used a repeatable-read, read-only transaction. Fingerprints include table names, row counts, and a SHA-256 multiset of canonical JSON row hashes, preserving duplicate counts. Sequence state was read without advancing sequences and matched separately. Schema-only dumps also matched after removing randomized `restrict` directives and the two dump-version comments: Debian-Recovered runs PostgreSQL 17.10, Debian3 17.11. The apparent raw schema-hash difference was therefore dump metadata, not a detected schema difference. No row contents, role passwords, or dump contents were printed or saved.

This is a point-in-time comparison, not a cross-distro atomic snapshot: both database servers were online during comparison and neither was made permanently read-only, so they can diverge later. Shared cluster roles, large-object contents, and non-database unique files are not covered by these table fingerprints. Recheck any changing state at the eventual retirement boundary. Final Windows inventory showed Debian3 stopped again, Debian-Recovered running, and Debian-Backup stopped. No termination command was issued; the reason Debian3 stopped was not diagnosed. Debian-Backup was not started or modified.

### Last completed migration evidence — not a fresh runtime check

Exact-root Pi session `01a06e20-7135-75c8-af5d-495ff8ed30c8` (4–5 September) contains tool results supporting:

- Debian3 SSH permissions, 860 Pi sessions, 27 transcripts, and McFly integrity verified.
- PostgreSQL logical restores: `boatdata_direct` 112,996 rows and `boatdata_staging` 121,623 rows. Dumps retained at `~/recovery/postgresql-20260904T232427Z`.
- 235 Restic snapshots: 234 inherited and one Debian3 snapshot. Structural check passed; a full latest-snapshot restore recovered 1.028 GiB and root-run landmark checks passed. This was not an all-history `check --read-data`.
- Debian3's systemd backup timer was enabled/active; Debian-Recovered's timer was disabled. Debian3 PostgreSQL used port 5433.
- Recovery-password confirmation was absent. This is missing escrow attestation, not proof that an escrowed password does not exist. Local restore success does not prove independent password recovery.
- No cold Debian3 whole-distro export was created. Git worktrees and Pi authentication configuration were not copied; a final unique-data assessment remains necessary before retirement.

### Recovery gates still open

Debian3 startup, timer state, escrow-marker absence, accessible recovery landmarks, retained backup/check records, and the bounded PostgreSQL comparison are verified. Remaining recovery gates are independent password recovery, a validated Debian3 whole-distro backup, and a final unique-data assessment before retirement. Do not start stopped distros merely to poll routine backup health. The existing system exporter requires six legacy Windows tasks and its validator assumes `/home/jack/boat-data-platform`; passing `-Distro Debian3` alone does not establish compatibility.

Independent password recovery needs owner interaction, without exposing credentials in session output or automating Bitwarden access. A secret-bearing whole-distro archive needs an explicitly approved protected storage location and maintenance window, followed by import/restore validation. Keep Debian-Recovered and Debian-Backup intact until these gates and a final unique-data/database comparison pass. No retirement is authorized by this record.

## Historical scheduling implementation evidence

The following reports preserve their original point-in-time claims. References to six authoritative tasks or a blocked systemd migration are superseded by the current evidence above.

Phase 1 is complete at commit `542e465063325671726ef5afc84c8a6fda985759`. It provides version-1 state validation, atomic JSON replacement, awake-time due policy, duration and consent policy, result classification, and an explicit read-only dry-run. Existing six-task registration and wrapper code were not changed.

## Verified evidence

- The exact Windows-source worktree passed `./scripts/wsl-backup/test-all fast` from WSL: 44 home assertions, 19 system assertions, and PSScriptAnalyzer 1.25.0 with no findings in nine paths. `git diff --check` passed.
- The dry-run failed closed when state was absent, reported the six existing tasks, and did not create the requested state file.
- No production task, Restic operation, credential, marker, deployment state, or production coordinator state was changed.

## Phase 2 candidate outcome

The fixture-only Phase 2 shadow coordinator now models explicit previous awake-attempt state, configurable failure/deferral warning thresholds, projected consecutive counters across invocations, success resets, resume and 15-minute interval decisions, no-change versus changed success, strict exit-code/result contracts, overlap refusal, suspension-independent health, backup-gated maintenance, and first-eligible selection in explicit fixture policy order. Complete fixture validation fails closed even when overlap, lock, or not-due branches would not consume a field.

Fresh controller review ran the direct PowerShell 7 test (38 assertions) and canonical exact-source WSL `./scripts/wsl-backup/test-all fast` (44 home, 38 shadow, 19 system assertions; PSScriptAnalyzer 1.25.0 clean in 11 paths). Six valid structured-output semantic mutations were killed through shared retained contract predicates, including exact-threshold and success-reset state transitions, and `git diff --check` passed. No WSL backup, Restic, Scheduled Task, maintenance, notification, credential, marker, deployment, or production-state operation was performed; production tasks and the existing wrapper remain unchanged. The Phase 2 fixture-only evidence gate is accepted for source integration review.

## Current integration assurance

Commit `d9466643d271f6d195ca7690f9c193693fdafce9` owns the reviewed Phase 2 fixture-only coordinator, retained test, fast-lane hook, and test evidence. Commit `25ce1c92cea276addd77d7e8afc1c143f5f4544e` owns the Phase 2 plan and status closeout. Production tasks and state are unchanged.

Relay `a96508aa-768d-41ab-ba1c-f1766d4e5c7d` is closed as `accepted-complete`; its executor changed no project or external state.

## Integration-readiness review

`source integration complete`: controller review covered the coordinator, retained test, fast-lane hook, and evidence committed at `d946664`. The coordinator requires explicit `-ReadOnly`, reads only an explicit fixture, and contains no WSL, Restic, Scheduled Task, maintenance, notification, credential, marker, deployment, or production-state operation. `NEXT-SESSION.md` remains relay control metadata and was not committed.

This completion does not authorize production-state or task integration. Warning thresholds are mandatory explicit fixture policy inputs; the tests use value `2` only to prove exact boundary behavior across projected invocations, not to approve a production value.

The controller approved [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md) without amendment: failure and lock-deferral warnings occur on the second consecutive eligible outcome; suspension for any duration neither increments nor resets counters; duplicate same-episode notifications use the tested six-hour wall-clock window; one tracked JSON policy owns the values; and the atomic persistence, fail-closed recovery, disposable acceptance-test, and mutation contract is settled.

## Production-state adapter integration

Commit `1e2b97a697e8952fbff25c9d414575cd9329f5c1` integrated the approved tracked policy, schema-2 state shared with the existing dry-run, strict policy/state/result validation, cross-process pending-attempt recovery, same-directory flushed atomic replacement, abandoned temporary cleanup, notification episodes, suppression-aware malformed-state diagnostics, and an explicit backup-before-maintenance gate.

Controller review accepted the source-only adapter. The direct retained suite passed 115 assertions. Eight structured semantic mutations were killed at their intended retained assertions. The exact Windows source passed the canonical WSL fast lane: 44 existing home assertions, 38 shadow assertions, 115 adapter assertions, eight adapter mutations, 19 system assertions, and PSScriptAnalyzer 1.25.0 clean across 14 paths. The adapter contains no WSL, Restic, Scheduled Task, message, marker, deployment, or maintenance adapter.

No production state, task, WSL/Restic operation, deployment, credential, or marker changed. The existing six production tasks remain authoritative.

## Phase 3 source integration

Commit `6a84654246f1c8861c44e78f7a4de7af6b637319` integrates strict source-only long-job policy/state, a timed PowerShell 7 Yes/No UI, no-session and AC-power deferral, exact 24-hour snooze boundaries, one-operation fixed dispatch, deterministic measured and conservative duration evidence, and idle-sleep-only inhibition acquired after approval and released in `finally`. Windows `HEAD`, `origin/main`, and WSL chezmoi `HEAD` are synchronized at that commit with ahead/behind `0/0`; tools documentation is integrated at `9145e2470087f99723d116d765ce4c66cd6622f4`. Failed or interrupted work remains due; explicit sleep, lid-close, shutdown, and user intent are not inhibited.

All execution seams were disposable and injected. The direct retained suite passed 55 assertions. Seven valid semantic mutations—removed consent, ignored snooze, changed dispatch, bypassed session or power gates, skipped sleep release, and marked failed/interrupted work complete—were killed at their named assertions. The canonical exact-source WSL fast lane passed with 44 home, 38 shadow, 115 state-adapter, 55 Phase 3, and 19 system assertions; all eight state-adapter and seven Phase 3 mutations passed; PSScriptAnalyzer 1.25.0 was clean across 18 paths.

No WSL, Restic, Scheduled Task, credential, marker, deployed file, production state, or production command was touched. The existing six tasks remain authoritative.

## Phase 4 Linux-scheduling architecture correction

The undeployed Windows-driven Phase 4 candidate was rejected and removed. Routine Restic work now has a Linux-owned source candidate: `wsl-home-scheduler` serializes backup, health status, and due retention with Linux locks and atomic state; `wsl-home-scheduler.timer` starts after the distro starts naturally and repeats every 15 minutes only while Linux remains running. Setup installs these units and never registers Windows home-backup tasks.

The repository `AGENTS.override.md` now makes the OS boundary explicit: Windows must not start WSL merely to inspect, poll, schedule, or run routine Linux-owned work. Windows remains available only for visible consent, AC-power state, idle-sleep inhibition, and whole-distro export.

Disposable scheduler tests pass 30 assertions and five attributed semantic mutations covering backup gating, exact retention due boundaries, malformed-state refusal, overlap refusal, atomic state replacement, systemd unit shape, and absence of Windows execution boundaries. The reversible migration fixture passes 78 assertions and five attributed mutations covering inventory completeness/drift, durable rollback evidence, exact restoration, interruption recovery, explicit cutover, and the observation deletion gate. Final canonical fast-lane totals are recorded in [`TESTING.md`](TESTING.md).

A production migration preflight on 28 August 2026 atomically captured and revalidated all six enabled deployed task definitions outside Git. Linux installation then failed closed before copying files because Debian-Recovered was not booted with systemd (`systemctl is-system-running` reported `offline`; PID 1 was WSL init). No Windows task was disabled or deleted, no Linux timer was installed or enabled, and no coordinator, Restic operation, credential, or marker was changed. The migration remains at the stable `Inventoried` state; enabling systemd requires a separately reviewed distro-boot configuration change before preflight can continue.

All six deployed Windows tasks therefore remain enabled and authoritative, and can still invoke WSL unconditionally. Delete them only after a successful later cutover and observation gate.
