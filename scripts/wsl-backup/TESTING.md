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
| `fast` | Bash syntax, ShellCheck, isolated setup and CLI contracts, Windows task/notification policy, system helper contracts, PSScriptAnalyzer | None |
| `integration` | Real disposable Restic repository, backup, retention, structural/full-data checks, staged restore, and read-only production status | Creates and removes only `/var/tmp/restic-home-test.*`; production inspection is read-only |
| `all` | `fast` followed by `integration` | Same as `integration` |

The setup tests use `WSL_BACKUP_DESTDIR` plus fake PowerShell 7, `wslpath`, `sudo`, Restic, and SQLite adapters. The operator tests inject command paths through `WSL_BACKUP_HOME_COMMAND`, `WSL_BACKUP_SUDO`, `WSL_BACKUP_POWERSHELL`, and `WSL_BACKUP_SYSTEM_SCRIPT_CONFIG`. These are test seams, not alternate production configuration interfaces.

## Stable contracts tested

- Setup never needs root when installing into a disposable `DESTDIR`.
- Both the password file and repository config must exist before task registration.
- Existing task schedules are preserved unless force is explicit, while legacy PowerShell 5.1 actions migrate to PowerShell 7.
- Operator commands forward exact home arguments and system modes.
- Adapter failures propagate through the operator command.
- Windows tasks use PowerShell 7 and retain the six intended schedules.
- Duplicate notifications are suppressed for less than six hours and resume at the boundary.
- Existing system manifest, journal, task rollback, artifact, and retention contracts remain covered by the system suite.

## Semantic mutation evidence

The following mutations were executed one at a time and reverted. Each accepted kill failed at the intended stable-contract assertion.

| Boundary | Injected bug | Distinguishing case | Result |
|---|---|---|---|
| Setup registration gate | Repository password **or** config was sufficient | Password exists; config absent | Killed |
| Setup force policy | Default and forced task rebuilding were inverted | Ready repository, default then explicit force | Killed |
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

## Explicitly deferred scope

A full failure-injection state machine covering every stage of whole-system export was considered and deliberately deferred. Existing crash-journal tests, helper tests, recovery smoke tests, and the proven production export remain the evidence for that boundary. This test suite does not claim exhaustive stage-by-stage export fault injection.
