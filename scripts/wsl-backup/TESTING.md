# WSL backup testing reference

This page defines the local test strategy. Tests deliberately run from WSL and use the built-in Windows PowerShell for Windows components. There is no GitHub Actions workflow; the canonical gate is the local `test-all` command.

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

The setup tests use `WSL_BACKUP_DESTDIR` plus fake `powershell.exe`, `wslpath`, `sudo`, Restic, and SQLite adapters. The operator tests inject command paths through `WSL_BACKUP_HOME_COMMAND`, `WSL_BACKUP_SUDO`, `WSL_BACKUP_POWERSHELL`, and `WSL_BACKUP_SYSTEM_SCRIPT_CONFIG`. These are test seams, not alternate production configuration interfaces.

## Stable contracts tested

- Setup never needs root when installing into a disposable `DESTDIR`.
- Both the password file and repository config must exist before task registration.
- Existing task schedules are preserved unless force is explicit.
- Operator commands forward exact home arguments and system modes.
- Adapter failures propagate through the operator command.
- Windows tasks use the built-in Windows PowerShell and retain the six intended schedules.
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
| Notification boundary | Six-hour comparison changed from `<` to `<=` | Same failure exactly six hours old | Killed |

The first scheduler trial was rejected as invalid because an adjacent force assertion failed before the intended missing-task assertion. The assertions were reordered, and the retry was killed at the intended seam. Mutation evidence covers guard, precedence, mapping, side-effect, and boundary classes. No mutation debt remains for the setup, operator-dispatch, task-registration, or notification boundaries audited in this pass.

## Explicitly deferred scope

A full failure-injection state machine covering every stage of whole-system export was considered and deliberately deferred. Existing crash-journal tests, helper tests, recovery smoke tests, and the proven production export remain the evidence for that boundary. This test suite does not claim exhaustive stage-by-stage export fault injection.
