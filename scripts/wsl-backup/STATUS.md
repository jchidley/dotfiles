# WSL backup and recovery status

## Current recovery position — 5 September 2026

This section owns current operational evidence; the phase reports below are historical source/integration records, not current deployment instructions. See [`TASKS.md`](TASKS.md) for incomplete work and [`RECOVERY-PLAN.md`](RECOVERY-PLAN.md) for the active bounded sequence and approval gates.

**Bottom line:** the bounded migration/recovery inspection is complete. Retained Restic restore evidence and the two boat-database comparisons passed. Independent password recovery, a validated Debian3 whole-distro generation, and the final unique-data/retirement gates remain open. No scheduler cutover needs to be replayed.

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
