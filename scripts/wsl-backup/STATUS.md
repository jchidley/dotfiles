# WSL backup scheduling status

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

No WSL, Restic, Scheduled Task, credential, marker, deployed file, production state, or production command was touched. The existing six tasks remain authoritative. The next authorization boundary is preparation of a source-only, disposable Phase 4 production-integration candidate; deployment and production migration remain unauthorized.
