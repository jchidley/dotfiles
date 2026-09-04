# WSL backup testing reference

This page defines the local test strategy. Tests deliberately run from WSL and use PowerShell 7 (`pwsh.exe`) for Windows components. There is no GitHub Actions workflow; the canonical gate is the local `test-all` command.

## Test lanes

```bash
./scripts/wsl-backup/test-all fast
./scripts/wsl-backup/test-all integration
./scripts/wsl-backup/test-all all
```

| Lane | Coverage | Production effects |
|---|---|---|
| `fast` | Bash syntax, ShellCheck, isolated Linux scheduler/setup/CLI contracts, retained legacy Windows policy tests, system helper contracts, PSScriptAnalyzer | None |
| `integration` | Real disposable Restic repository, backup, retention, structural/full-data checks, staged restore, and read-only production status | Creates and removes only `/var/tmp/restic-home-test.*`; production inspection is read-only |
| `all` | `fast` followed by `integration` | Same as `integration` |

The setup tests use `WSL_BACKUP_DESTDIR` plus fake PowerShell 7, `wslpath`, `sudo`, Restic, and SQLite adapters. The operator tests inject command paths through `WSL_BACKUP_HOME_COMMAND`, `WSL_BACKUP_SUDO`, `WSL_BACKUP_POWERSHELL`, and `WSL_BACKUP_SYSTEM_SCRIPT_CONFIG`. These are test seams, not alternate production configuration interfaces.

## Stable contracts tested

- Setup never needs root when installing into a disposable `DESTDIR`.
- Ordinary setup installs Linux systemd units but never enables the timer.
- Setup never registers Windows tasks for routine home-backup work; enablement belongs only to the explicit migration cutover.
- The Linux scheduler runs backup first, blocks later work after failure/deferral, and owns retention due state atomically.
- Operator commands forward exact home arguments and system modes.
- Adapter failures propagate through the operator command.
- Retained legacy-task helpers still describe and validate the six deployed schedules for rollback; setup no longer calls them.
- Duplicate notifications are suppressed for less than six hours and resume at the boundary.
- Existing system manifest, journal, task rollback, artifact, and retention contracts remain covered by the system suite.

## Semantic mutation evidence

The following mutations were executed one at a time and reverted. Each accepted kill failed at the intended stable-contract assertion.

| Boundary | Injected bug | Distinguishing case | Result |
|---|---|---|---|
| Operator system dispatch | Every system command became `Status` | Requested `Preflight` | Killed |
| Operator failure propagation | Home adapter status 7 was converted to success | Fake home adapter exits 7 | Killed |
| Task registration decision | Missing-task/force logic changed from OR to AND | Task missing; force false | Killed after isolating the intended assertion |
| Task trigger mapping | Backup interval unit changed from minutes to days | Backup specification with 15-minute interval | Killed |
| Notification boundary | Six-hour comparison changed from `<` to `<=` | Same failure exactly six hours old | Killed |
| Phase 2 suspension boundary | Shadow due logic counted suspended days as awake time | Identical awake clocks with zero versus three suspended days | Killed at the shared suspension-independence predicate |
| Phase 2 lock result | Exit 75 deferral was marked complete | First lock with explicit prior counters and threshold | Killed at the shared lock due/non-alerting predicate |
| Phase 2 no-change result | Explicit no-change was collapsed into changed success | Exit 0 with `NoChange` at the exact interval | Killed at the shared result-distinction predicate |
| Phase 2 maintenance serialization | Selection allowed two overdue items | Two eligible items in explicit fixture policy order | Killed when the mutant emitted two maintenance decisions |
| Phase 2 threshold boundary | Warning comparison changed from `>=` to `>` | Second projected deferral at threshold 2 | Killed at the exact-threshold predicate |
| Phase 2 recovery state | Successful `NoChange` preserved the prior failure count | Successful invocation starting at the warning boundary | Killed at the recovery-reset predicate |

The Phase 2 shadow test uses explicit JSON fixtures and `-ReadOnly`; it does not invoke WSL backup, Restic, Scheduled Tasks, maintenance, notifications, or production state. The direct PowerShell 7 command passed with 38 assertions. From WSL, the canonical `./scripts/wsl-backup/test-all fast` passed with 44 home assertions, 38 shadow assertions, 19 system assertions, and PSScriptAnalyzer 1.25.0 with no findings in 11 paths. `git diff --check` passed.

The completion mutation command was the retained test's self-restoring temporary-copy loop in `scripts/wsl-backup/home/Test-WslHomeSchedulingShadow.ps1`; each mutant emitted valid structured coordinator JSON and was killed by its named retained assertion:

| Mutation | Retained assertion | Result |
|---|---|---|
| Count suspended duration as awake time (`-or $suspendedDays -gt 0` in due logic) | Shared suspension-independence predicate | Killed |
| Mark exit-75 `Lock` complete (`Due = $false`) | Shared lock due/non-alerting predicate | Killed |
| Collapse `NoChange` into `Changed` | Shared no-change distinction predicate | Killed |
| Allow two maintenance selections (`Select-Object -First 2`) | Shared one-selection/fixture-order predicate | Killed with valid two-decision JSON |
| Delay threshold warning by changing `-ge` to `-gt` | Shared exact-threshold predicate on the second projected invocation | Killed |
| Preserve failure count after successful `NoChange` | Shared recovery-reset predicate | Killed |

The mutation loop uses `try`/`finally` to remove its unique temporary directory. No mutation exception, replacement miss, malformed output, or unrelated assertion was counted as a kill.

## Current Phase 2 evidence recheck

`pwsh.exe -NoLogo -NoProfile -NonInteractive -File scripts/wsl-backup/home/Test-WslHomeSchedulingShadow.ps1` passed with 38 assertions. The exact Windows-source WSL `./scripts/wsl-backup/test-all fast` passed with 44 home assertions, 38 shadow assertions, 19 system assertions, and PSScriptAnalyzer clean in 11 paths. The Phase 2 fixture-only evidence gate is complete; source integration remains controller-owned and production integration remains excluded.

Retained cases additionally prove interval reset at awake minutes 15/16/29/30, strict booleans, complete validation on overlap and not-due branches, exact exit-75 classification, nondecreasing awake clocks, overlap refusal, backup-gated maintenance, explicit fixture ordering, projected consecutive counters, threshold crossing on later invocations, success resets, and rejection of contradictory or orphaned health counters. Threshold value `2` is test policy data only; no production threshold is approved.


The first scheduler trial was rejected as invalid because an adjacent force assertion failed before the intended missing-task assertion. The assertions were reordered, and the retry was killed at the intended seam. Mutation evidence covers guard, precedence, mapping, side-effect, and boundary classes. No mutation debt remains for the setup, operator-dispatch, task-registration, or notification boundaries audited in this pass.

## Production health-state adapter evidence

The source-only adapter gate from [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md) now passes 115 retained assertions in `Test-WslHomeSchedulingStateAdapter.ps1`. Every adapter process uses a unique temporary state/policy directory and a fake fixed PowerShell command. The suite proves strict policy and schema-2 state validation, policy-hash drift refusal, separate-process counters, suspension lasting weeks without invented awake time, exact failure/deferral and six-hour notification boundaries, success resets, overlap refusal, strict exit/result classification, shared dry-run schema compatibility, pending-attempt retry without inferred success, complete old/new generations at atomic fault points, abandoned temporary cleanup, nested duplicate rejection, suppression-aware state diagnostics, and absence of production adapters.

`Test-WslHomeSchedulingStateAdapterMutations.ps1` creates one disposable source copy per mutant and requires a nonzero retained-test result containing the named assertion. It rejects parser or harness failures. Eight mutations were killed at the intended seams:

| Mutation | Retained assertion |
|---|---|
| Delay warning past the exact threshold | Second eligible failure warns even when attempts are weeks apart |
| Run backup at an ineligible periodic event | Weeks of suspension do not create an awake-time attempt |
| Preserve failure count after success | No-change resets both counters and opens the backup gate |
| Accept an unknown state schema | Unknown state schema fails closed |
| Infer success when recording a pending attempt | Interruption never infers backup success |
| Remove the pre-replacement fault boundary | Pending pre-replacement termination leaves the old generation |
| Preserve a notification episode after success | Success ends the notification episode |
| Open the maintenance gate after failure | Failure blocks the backup-before-maintenance gate |

The canonical fast lane passed with 44 existing home assertions, 38 shadow assertions, 115 adapter assertions, all eight adapter mutations, 19 system assertions, and PSScriptAnalyzer 1.25.0 clean across 14 paths. These are disposable source-integration results, not deployment or production-operation evidence.

## Phase 3 consent evidence

`Test-WslHomeLongJobConsent.ps1` uses one unique temporary root, strict copied policy/state, fake fixed commands, and injected session, power, prompt, monotonic-clock, and idle-sleep adapters. Its 55 retained assertions prove exact fixed dispatch after Yes; no execution after No, timeout, ignored prompt, battery policy, or absent session; exact 24-hour snooze boundaries; overlap refusal; prompt-text injection resistance; idle-sleep-only acquisition after approval and release after success, failure, and interruption; due retention after failure/interruption; and deterministic measured plus conservative duration history.

`Test-WslHomeLongJobConsentMutations.ps1` creates one parser-valid disposable source copy per mutation and accepts a kill only when the named retained assertion appears. Seven semantic mutations were killed:

| Mutation | Retained assertion |
|---|---|
| Remove the consent check | No never runs the operation and keeps it due |
| Ignore `SnoozeUntil` | Snooze suppresses prompts just before its exact boundary |
| Dispatch a different command file | Fixed reviewed operation identity reaches the command unchanged |
| Allow an absent interactive session | Absent session defers before prompting or running |
| Allow battery-power execution | Battery policy prevents prompting and running |
| Skip idle-sleep release | Idle-sleep inhibition is released after approved success |
| Mark failed or interrupted work complete | Failed work remains due |

The direct retained and mutation suites passed. The canonical exact-source WSL fast lane passed with 44 home assertions, 38 shadow assertions, 115 state-adapter assertions, 55 Phase 3 assertions, all eight state-adapter and seven Phase 3 mutations, 19 system assertions, and PSScriptAnalyzer 1.25.0 clean across 18 paths. Commit `6a84654` integrates this source evidence. The Phase 3 candidate contains no production command adapter and touched no WSL, Restic, Scheduled Task, credential, marker, deployed file, or production state.

## Phase 4 Linux-scheduler evidence

`test-scheduler.sh` uses only a temporary Linux state directory, lock, fake fixed home command, and injected clock. Its 30 retained assertions prove backup-before-health-before-retention ordering, no later work after backup or status failure, exact daily retention boundaries, lock deferral propagation, strict state validation, atomic state replacement, overlap refusal, systemd service/timer shape, and absence of `wsl.exe`, PowerShell, or Scheduled Task execution from the Linux scheduler.

`test-scheduler-mutations.sh` makes one parser-valid disposable source copy per mutation and requires failure at its named retained assertion:

| Mutation | Retained assertion |
|---|---|
| Ignore backup failure | Backup failure propagates and blocks all later Linux-owned work |
| Run retention before its exact due boundary | Retention remains not due before its exact Linux-owned boundary |
| Accept an unknown state schema | Malformed scheduler state fails closed before backup |
| Ignore the coordinator lock | Overlap refusal runs no second Linux coordinator |
| Copy state non-atomically | Atomic scheduler state writes leave no temporary file |

The setup/CLI fixture additionally proves that setup installs the scheduler and systemd units under a disposable `DESTDIR`, never enables the timer, never calls `Register-WindowsTasks.ps1`, and rejects the retired `--force-windows-tasks` option. No scheduler test invokes real Restic, systemd, WSL, Windows Task Scheduler, credentials, markers, or deployed state.

## Reversible migration evidence

`Test-WslHomeSchedulingMigration.ps1` uses disposable task and Linux adapters. Its 78 retained assertions prove exact six-task inventory and SHA-256 retention; rejection of missing, duplicate, renamed, unexpected, and drifted tasks; durable inventory before cutover; Linux installation without implicit enablement; independent disable and restore read-back; exact XML/enabled-state rollback after five injected interruption points; explicit timer enablement; stable-state verification; refusal to delete without a matching true observation record; absence of routine setup registration; and removal of `Register-WindowsTasks.ps1` from active source.

`Test-WslHomeSchedulingMigrationMutations.ps1` creates parser-valid source copies and requires each to die at its named retained assertion. Five attributed mutations were killed: accepting an incomplete inventory, ignoring task-definition drift, losing enabled state during rollback, skipping automatic rollback, and accepting a false observation record.

The Linux migration helper additionally fails closed unless systemd is active, verifies units with `systemd-analyze`, compares installed files with reviewed source hashes, rejects Windows execution boundaries, and keeps installation separate from explicit timer enablement.

## Explicitly deferred scope

A full failure-injection state machine covering every stage of whole-system export was considered and deliberately deferred. Existing crash-journal tests, helper tests, recovery smoke tests, and the proven production export remain the evidence for that boundary. This test suite does not claim exhaustive stage-by-stage export fault injection.
