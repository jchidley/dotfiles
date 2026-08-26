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
| Phase 2 suspension boundary | Shadow awake output included suspended days as awake minutes | Three suspended days; zero awake minutes | Shallow: detected an output change but did not prove due-time or health behavior |
| Phase 2 lock result | Exit 75 deferral was marked complete | Linux exit 75 with explicit Lock result | Provisional: direct result assertion detected it, but repeated-deferral health remains uncovered |
| Phase 2 no-change result | Explicit no-change was collapsed into changed success | Exit 0 with NoChange result | Provisional: direct result assertion detected it |
| Phase 2 maintenance serialization | Selection allowed two overdue items | Two eligible overdue maintenance items | Rejected: the harness accepts an incidental exception as a kill |

The uncommitted Phase 2 candidate test reported 18 passing assertions. Its fixture is explicit JSON and read-only; it does not invoke WSL, Restic, Scheduled Tasks, maintenance, notifications, or production state. The canonical fast lane then passed with 44 existing home assertions, 18 shadow assertions, 19 system assertions, and PSScriptAnalyzer 1.25.0 with no findings in 11 paths. `git diff --check` passed.

Controller review rejected this evidence as the Phase 2 gate. The retained tests must directly prove elapsed awake time from the previous attempt, no immediate alert for one lock deferral, no maintenance after backup deferral/failure, and suspension-independent due and health decisions. Mutation trials must fail through the named retained assertion; an unrelated exception is not an accepted kill.

The first scheduler trial was rejected as invalid because an adjacent force assertion failed before the intended missing-task assertion. The assertions were reordered, and the retry was killed at the intended seam. Mutation evidence covers guard, precedence, mapping, side-effect, and boundary classes. No mutation debt remains for the setup, operator-dispatch, task-registration, or notification boundaries audited in this pass.

## Explicitly deferred scope

A full failure-injection state machine covering every stage of whole-system export was considered and deliberately deferred. Existing crash-journal tests, helper tests, recovery smoke tests, and the proven production export remain the evidence for that boundary. This test suite does not claim exhaustive stage-by-stage export fault injection.
