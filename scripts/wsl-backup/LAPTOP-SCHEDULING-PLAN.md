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

- Run a backup shortly after login, unlock, or resume.
- Repeat at most every 15 minutes while the laptop remains awake.
- Use Restic's unchanged-data behaviour deliberately; add `--skip-if-unchanged` if fixture and production tests confirm that it preserves the required status and retention semantics.
- Record a successful attempt even when no new snapshot is needed.
- Do not replay every missed interval after suspension.
- Do not depend on a pre-suspend hook. A best-effort lock/suspend trigger may be evaluated later, but Windows cannot guarantee enough time for Restic to finish before sleep.

The post-resume run closes the short interval in which work may have changed and the laptop suspended before the next periodic backup. Loss of the laptop while suspended is outside the protection boundary of the current same-disk repository and requires independent replication.

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

## Task Scheduler shape

Target one normal coordinator task rather than six independently due operational tasks.

- Trigger after logon/unlock/resume, with a short stabilization delay.
- Repeat every 15 minutes while Windows is awake.
- Use `StartWhenAvailable` only to create one reconciliation run, not to replay missed work.
- Use `MultipleInstances IgnoreNew` or the equivalent coordinator lock.
- Run as the interactive user under PowerShell 7 (`pwsh.exe`).
- Keep long-operation consent visible only in an interactive session.

The implementation must verify which Task Scheduler trigger combination reliably represents resume and unlock on this Windows/WSL installation before changing production tasks. Event-trigger XML is acceptable only with fixture tests and read-back validation.

## Implementation phases

### Phase 1 — State and policy, no production schedule changes

- Add pure PowerShell functions for due calculation, awake/suspended interpretation, duration estimates, automatic-versus-consent policy, snooze, and failure/deferral classification.
- Define and validate the atomic state schema.
- Add deterministic tests for clock changes, multi-day suspension, repeated resume, lock deferral, failed operations, snooze boundaries, unknown duration, and schema rejection.
- Add read-only reporting showing what the coordinator would do against production state.

**Gate:** tests and a dry-run report pass without modifying scheduled tasks or running maintenance.

### Phase 2 — Routine coordinator

- Implement the single coordinator and post-resume/periodic backup semantics.
- Record successful no-change attempts separately from snapshot creation.
- Replace wall-clock freshness with awake-time attempt health.
- Prove exact exit-code and lock-deferral behaviour with fixtures and semantic mutations.

**Gate:** a shadow-mode coordinator makes the same safe backup decisions expected from recorded wake/activity scenarios.

### Phase 3 — Consent and long-job execution

- Implement the PowerShell 7 Yes/No prompt with no-interactive-session deferral.
- Add AC-power detection, idle-sleep inhibition, guaranteed cleanup, fixed-command dispatch, 24-hour snooze, and duration recording.
- Test Yes, No, timeout, battery, interruption, duplicate prompt suppression, command-injection resistance, and failed long work remaining due.

**Gate:** disposable operations prove that no long command can run without a current explicit approval.

### Phase 4 — Reversible production migration

- Install the coordinator while leaving existing task definitions recoverable.
- Disable, rather than immediately delete, the six old tasks.
- Register and read back the new trigger/action/settings.
- Run a post-resume production backup exercise.
- Successfully rerun the currently failed full-data check with consent and clear its marker only on success.
- Observe retention and at least one due maintenance decision.
- Retain a documented rollback command until the observation period completes.

**Gate:** no catch-up storm, no suspension-only stale warning, routine snapshots remain healthy, and a declined long operation never runs.

### Phase 5 — Documentation and cleanup

- Update the command reference, task inventory, status output, and current capability page.
- Remove old tasks only after the observation gate.
- Record measured durations and the final task policy without turning the historical research note into live status.

## Required regression tests

At minimum, tests must prove:

- three suspended days do not create a stale failure;
- work followed by suspend is backed up on the next resume opportunity;
- multiple overdue operations produce one serialized decision;
- a lock conflict remains due and retries rather than being marked complete;
- a long operation never runs after No, timeout, or absent interactive session;
- Yes can dispatch only the operation shown;
- snooze suppresses prompts until its exact boundary;
- battery policy prevents accidental heavy work;
- idle-sleep inhibition is always released;
- interruption retains recoverable state;
- PowerShell 5.1 is rejected and every task action uses `pwsh.exe`;
- setup is idempotent and migration rollback preserves the original task definitions;
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

The next implementation session should complete **Phase 1 only**: state schema, pure scheduling/consent policy, deterministic tests, and a read-only production dry run. It must not alter production tasks, clear the failed full-data-check marker, or execute long maintenance.
