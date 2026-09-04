# Laptop-aware WSL backup scheduling plan

This is the canonical implementation plan for replacing fixed-time WSL backup maintenance with scheduling that reflects real backup opportunities on a suspending laptop. It covers routine `/home/jack` snapshots, monitoring, retention, repository checks, pruning, and consent for long-running work. It does not redesign Restic storage, combined recovery, or independent replication.

The current commands and deployed behaviour remain documented in [`README.md`](README.md), [`home/README.md`](home/README.md), and [`system/README.md`](system/README.md) until each phase below is deployed and verified.

## Problem to solve

The current six Windows tasks use fixed or repeating wall-clock schedules with `StartWhenAvailable`. The laptop does not run them while suspended. On resume, missed tasks can start together even though the intended work did not become more urgent while the machine was asleep.

This creates three incorrect behaviours:

1. Snapshot freshness is measured in wall-clock time, so an unchanged suspended laptop can appear stale.
2. A short work session can end before the next 15-minute snapshot; the changes are not captured until a later wake.
3. overdue backup, monitor, and maintenance tasks can collide when Windows runs them together after wake.

The first natural 30-day production full-data check demonstrated the collision on 25 August 2026. It resumed at 13:31, met concurrent catch-up activity, and failed on a Restic repository lock. Routine backup recovered at 13:44. The full-data-check failure marker must remain until a successful production rerun.

## Required behaviour

### Backup opportunity

Measure routine protection against time when the laptop is awake, not elapsed wall-clock time.

- Reconcile shortly after the distro starts naturally and every 15 minutes while it remains running; after Windows resume, the Linux timer continues only if the distro was already active.
- Never start a stopped distro from scheduling. A stopped distro cannot have accumulated Linux-side work, so there is no backup opportunity to record and `wsl --shutdown` remains authoritative.
- Do not use Windows login, unlock, resume, or periodic triggers to start WSL for routine work.
- Use Restic's unchanged-data behaviour deliberately; add `--skip-if-unchanged` if fixture and production tests confirm that it preserves the required status and retention semantics.
- Record a successful attempt even when no new snapshot is needed.
- Do not replay every missed interval after suspension.
- Do not depend on a pre-suspend hook. A best-effort lock/suspend trigger may be evaluated later, but Windows cannot guarantee enough time for Restic to finish before sleep.

If the distro was running across Windows suspend, its resumed Linux timer closes the short interval in which work may have changed before suspend. If the distro was stopped, there was no Linux-side change opportunity and scheduling must not start it. Loss of the laptop while suspended is outside the protection boundary of the current same-disk repository and requires independent replication.

### Monitoring

Replace the rule "newest snapshot is at most 30 minutes old" with opportunity-aware health.

The coordinator must distinguish:

- no backup opportunity because the laptop was suspended;
- a successful awake-time backup attempt with no changes;
- changed data captured successfully;
- an operation deferred because another operation owns the lock;
- repeated real failures while the laptop is awake.

A suspended interval alone must never create a stale warning. Alert when an immediate post-resume or periodic awake-time attempt repeatedly fails, not merely because the latest snapshot has an old timestamp. Duplicate notifications remain suppressed.

Do not add a persistent inotify watcher in the first implementation. The initial recovery-point bound is the post-resume trigger plus the 15-minute awake-time interval. A watcher can be reconsidered only if measured backup scanning cost or recovery-point evidence justifies the extra WSL lifetime and complexity.

### Serialization and due work

Replace independent catch-up execution with one coordinator and one durable due ledger.

Each coordinator run must:

1. refuse overlapping coordinator instances;
2. create or verify the routine home backup first;
3. update backup-attempt health;
4. determine which maintenance operations are due;
5. automatically run only bounded short work;
6. offer at most one consent-required operation;
7. record the outcome atomically.

A lock conflict is a deferral, not a successful run and not immediately a user-facing failure. The operation remains due and is retried later. Repeated deferrals while the laptop is awake eventually become a diagnostic warning.

## Automatic and consent-required operations

| Operation | Default policy |
|---|---|
| Incremental home backup | Automatic after resume and every 15 awake minutes |
| Successful no-change attempt | Record automatically |
| Backup health evaluation | Automatic and read-only |
| Retention without pack reclamation | Automatic when due if historical runtime remains bounded |
| Structural check | Automatic only while its measured runtime remains below the long-job threshold |
| Prune | Ask before running |
| Full-data read check | Ask before running |
| Whole-system export | Always ask before running because it stops the distro |

An operation is long when any of these is true:

- its most relevant previous successful duration exceeded two minutes;
- recent duration evidence predicts more than two minutes;
- it is intrinsically disruptive, such as a whole-system export;
- no trustworthy duration evidence exists for an operation expected to scan or rewrite substantial data.

The threshold must be configuration rather than duplicated logic. Runtime evidence may move structural checks or retention between automatic and consent-required treatment, but prune, full-data reads, and system exports remain explicitly gated unless this plan is revised.

## Consent prompt

A scheduled long operation must not start until the active user selects **Yes**. If no interactive desktop exists, leave the work pending and offer it after a later unlock.

The prompt must show facts rather than an opaque urgency score:

```text
WSL backup maintenance

A full repository data check is recommended.

Last successful check: 32 days ago
Backups since then: 146
Snapshots since then: 38
Previous duration: 17 minutes
Estimated duration: 15–25 minutes
Power: connected
Effect: routine Restic operations will wait
Reason: due every 30 days; previous attempt failed on a lock

Run it now?  [Yes] [No]
```

Show, where available:

- last successful completion and days elapsed;
- due interval and overdue duration;
- attempts, successful backups, or snapshots since completion;
- previous duration and a conservative recent range;
- previous failure or interruption;
- AC/battery state;
- expected service impact;
- the exact class of operation that will run.

**Yes** starts only the fixed reviewed operation represented by the prompt. Dynamic prompt text must never become command text.

**No** means defer, not fail and not complete. It must:

- keep the operation due;
- snooze another prompt for 24 hours by default;
- avoid repeated prompts from the 15-minute coordinator;
- preserve the evidence shown at the next offer.

An ignored or timed-out prompt behaves as **No**. A later implementation may offer explicit longer snooze choices, but the first interface remains a clear Yes/No decision.

## Power and suspension behaviour

Long work should normally be offered only on AC power. After **Yes**, the Windows controller may request that Windows not enter idle sleep until the operation finishes. It must always release that request in `finally` cleanup.

This is protection from automatic idle sleep, not authority to defeat explicit user intent indefinitely. Lid close, explicit sleep, shutdown, and process interruption remain possible. Interrupted work remains due and is offered again with the previous failure recorded.

## Durable state

Store coordinator state under `%LOCALAPPDATA%\WSLHomeRestic` using atomic JSON replacement. Keep credentials out of this state.

The schema must include at least:

- schema version;
- last coordinator attempt and success;
- last post-resume attempt and success;
- consecutive backup failures and deferrals;
- for each maintenance operation:
  - last attempt and success;
  - last result;
  - measured duration history sufficient for a conservative estimate;
  - due interval;
  - last prompt and `SnoozeUntil`;
  - backup-attempt or snapshot counters at last success;
- currently approved operation, if any, with bounded lifetime;
- atomic-operation or recovery metadata needed after interruption.

Do not infer success from a missing process. Every state transition must be explicit and crash-safe. Reject unknown schema versions rather than guessing.

## Scheduling ownership

Routine home-backup work belongs to Linux because its data, Restic repository, credentials, locks, and commands are Linux-owned. Use one Linux `systemd` timer and coordinator:

- start two minutes after the distro starts naturally;
- repeat every 15 minutes while the distro remains running;
- use `Persistent=true` only to reconcile once after the distro next starts naturally;
- serialize backup, health evaluation, and bounded automatic maintenance with Linux locks and state;
- never use Windows Task Scheduler, background PowerShell, or `wsl.exe -d` to poll or run routine Linux-owned work;
- allow WSL idle teardown and preserve `wsl --shutdown` indefinitely.

Windows remains responsible only for capabilities Linux cannot own: visible desktop consent, AC-power state, temporary Windows idle-sleep inhibition, and whole-distro export. A Windows bridge may enter WSL only after current explicit consent for one fixed operation; it must never wake WSL to check whether work is due.

## Implementation phases

### Phase 1 — State and policy, no production schedule changes

**Completed:** commit `542e465` added the versioned state/policy foundation, deterministic tests, and explicit read-only dry-run. The exact Windows source passed the fast lane from WSL (44 home assertions, 19 system assertions, PSScriptAnalyzer clean). No production task, maintenance, credential, marker, deployment, or production-state change was made.

**Gate:** complete.

### Phase 2 — Routine coordinator

- Implement the single coordinator and post-resume/periodic backup semantics.
- Track elapsed awake time from the previous attempt so arbitrary periodic events cannot run backups more often than the configured interval or replay suspended time.
- Record successful no-change attempts separately from snapshot creation.
- Replace wall-clock freshness with awake-time attempt health.
- Treat one lock conflict as a non-alerting deferral that remains due, and select no maintenance in a run whose backup was deferred or failed.
- Prove exact exit-code, health, interval, and lock-deferral behaviour with fixtures and semantic mutations that fail at their intended retained assertions.

**Completed:** commit `d946664` added the fixture-only shadow coordinator, 38 retained assertions, six attributed semantic mutations, and the fast-lane hook. The canonical fast lane, PSScriptAnalyzer, and controller review passed. It models projected state only and performs no production operation; completion does not authorize deployment or production state.

### Phase 3 — Consent and long-job execution

- Implement the PowerShell 7 Yes/No prompt with no-interactive-session deferral.
- Add AC-power detection, idle-sleep inhibition, guaranteed cleanup, fixed-command dispatch, 24-hour snooze, and duration recording.
- Test Yes, No, timeout, battery, interruption, duplicate prompt suppression, command-injection resistance, and failed long work remaining due.

**Source integration complete:** commit `6a84654` integrates the controller-reviewed candidate with strict disposable policy/state plus injected interactive-session, power, prompt, monotonic-clock, command, and idle-sleep adapters. Its retained suite passed 55 assertions and seven attributed semantic mutations. The canonical fast lane passed with PSScriptAnalyzer 1.25.0 clean across 18 paths. It is not deployed and contains no production command adapter.

**Gate:** disposable operations prove that no long command can run without a current explicit approval. The integrated source satisfies this disposable gate; every production action remains separately authorized.

### Phase 4 — Linux-owned scheduling and reversible migration

**Architecture corrected; source and reversible migration prepared:** `wsl-home-scheduler` and `wsl-home-scheduler.timer` keep routine backup, status, retention due logic, locking, and atomic state inside Linux. The timer runs only while the distro exists naturally; neither setup nor the scheduler registers or invokes a Windows home-backup task. Ordinary setup installs units without enabling them. Disposable scheduler and migration tests prove backup-first ordering, exact retention boundaries, fail-closed state, overlap refusal, atomic replacement, complete task inventory, interruption recovery, exact rollback, explicit cutover, and the observation deletion gate.

The earlier uncommitted Windows coordinator candidate was removed rather than deployed. The integrated Phase 1–3 Windows source remains historical/disposable evidence and a possible basis for genuinely Windows-owned consent UI only; it is not the routine scheduler deployment target.

A production attempt retained and revalidated the exact six-task inventory, then stopped safely because Debian-Recovered was not booted with systemd. It changed no task, installed no Linux file, and ran no coordinator or Restic operation. Continuing requires a separately reviewed systemd boot-configuration change and distro restart.

The remaining production migration work is:

- make systemd active under a separately reviewed authorization, then install and verify the Linux service and timer without routine Windows wake-up;
- inventory and preserve all six legacy Windows task definitions;
- enable the Linux timer, verify a natural backup while the distro is already running, then disable all six legacy tasks rather than deleting them;
- verify `wsl --shutdown` remains authoritative and no Windows task restarts WSL;
- retain exact rollback definitions and enabled states through the observation period;
- design the Linux-origin request/Windows-consent bridge before resuming prune or full-data-check scheduling;
- successfully rerun the currently failed full-data check with consent and clear its marker only on success.

**Gate:** no catch-up storm, no suspension-only stale warning, routine snapshots remain healthy, and a declined long operation never runs.

### Phase 5 — Documentation and cleanup

- Update the command reference, task inventory, status output, and current capability page.
- Remove old tasks only after the observation gate.
- Record measured durations and the final task policy without turning the historical research note into live status.

## Required regression tests

At minimum, tests must prove:

- three suspended days do not create a stale failure or advance the awake-time interval;
- work followed by suspend is backed up on the next resume opportunity;
- arbitrary periodic events cannot schedule attempts more often than the awake-time interval;
- multiple overdue operations produce one serialized decision only after backup succeeds;
- a lock conflict remains due, creates no immediate warning, blocks maintenance for that run, and retries rather than being marked complete;
- a long operation never runs after No, timeout, or absent interactive session;
- Yes can dispatch only the operation shown;
- snooze suppresses prompts until its exact boundary;
- battery policy prevents accidental heavy work;
- idle-sleep inhibition is always released;
- interruption retains recoverable state;
- routine scheduler source and systemd units contain no Windows or `wsl.exe` invocation;
- setup never registers Windows routine-work tasks and installs the Linux timer idempotently;
- migration rollback preserves the original six Windows task definitions;
- notification and output normalization remain intact.

Use semantic mutations for the consequential policies: remove consent, invert due logic, treat sleep as awake time, mark deferral successful, ignore snooze, run two maintenance jobs, or dispatch a different operation. Every mutation must be killed at its intended assertion.

## Explicit non-goals

This plan does not yet:

- move backups to an independent physical device;
- escrow the Restic password;
- implement combined system-export-plus-home recovery;
- schedule whole-system downtime without consent;
- guarantee a backup can finish during the transition into suspend;
- add GitHub Actions.

Those remain separate recovery-capability work after laptop scheduling is safe.

## Immediate bounded objective

Commit `1e2b97a` integrated the reviewed source-only production-state adapter from [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md). It implements the tracked policy, durable projected counters and pending attempts, atomic replacement and interruption recovery, notification episodes, and strict disposable validation. It passed 115 retained assertions, eight attributed semantic mutations, the canonical fast lane, and controller review without changing production state or operations.

Commit `6a84654` integrates the reviewed Phase 3 source-only candidate. The integrated Phase 4 source replaces the rejected Windows-driven routine coordinator with Linux `systemd` scheduling and records the OS-ownership boundary in repository `AGENTS.override.md`. Its disposable evidence must remain green before integration. It adds no deployment authority. The next explicit authorization boundary is the reversible production migration: install and verify the Linux timer, preserve then disable the six Windows tasks, and observe natural in-distro scheduling. Do not alter production tasks, enable the timer, invoke production maintenance, clear the failed full-data-check marker, or perform that migration without separate authorization.
