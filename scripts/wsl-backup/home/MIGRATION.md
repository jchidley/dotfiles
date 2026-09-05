# Migrate routine scheduling to Linux

This how-to applies only to an installation that still has all six legacy `WSL Home Restic - *` tasks. It moves them to the Linux `systemd` timer without using generated task definitions as rollback evidence. It does not authorize prune, full-data checks, task deletion, marker clearing, or whole-system export.

**Not the current Debian3 next step:** the 5 September inspection found zero legacy tasks and an enabled Debian3 timer. Do not recreate tasks, restore legacy scheduling, or replay this procedure to satisfy its preconditions. Follow [`../RECOVERY-PLAN.md`](../RECOVERY-PLAN.md); current evidence is in [`../STATUS.md`](../STATUS.md).

Run the PowerShell commands from the canonical Windows checkout with PowerShell 7. The tool writes machine-specific evidence under `%LOCALAPPDATA%\WSLHomeRestic\migration`; keep that directory out of Git and preserve it through the observation period.

## Preconditions

- `Debian-Recovered` is already running. Migration actions refuse to start a stopped distro.
- PID 1 in the distro is `systemd`, and `systemctl is-system-running` reports `running` or `degraded`.
- The source checkout and disposable migration, scheduler, mutation, ShellCheck, and PSScriptAnalyzer tests have passed.
- The Restic repository and password already exist.
- All six expected Windows tasks are present at task path `\` with no additional `WSL Home Restic - *` task.

Ordinary `setup.sh` only installs files. It never enables the timer.

## Inventory and preflight

```powershell
$tool = './scripts/wsl-backup/home/Migrate-WslHomeScheduling.ps1'
& $tool -Action Inventory
& $tool -Action InstallOrVerifyLinux
& $tool -Action Verify
```

`Inventory` atomically retains exact exported XML, enabled state, path/name, triggers, actions, principal, settings, per-task SHA-256 hashes, and a task-set hash. Repeated inventory validates current tasks against that retained evidence rather than replacing it.

`InstallOrVerifyLinux` requires the distro to be running already. It installs reviewed source files without enabling the timer, runs `systemd-analyze verify`, compares installed/source SHA-256 hashes, rejects Windows execution boundaries, runs the coordinator manually once, and confirms a healthy status.

If systemd is inactive, stop. Enabling systemd changes distro boot configuration and requires its own reviewed authorization; the migration tool does not guess or make that change.

## Cut over

```powershell
& $tool -Action DisableLegacy
& $tool -Action Verify
```

Cutover first writes a durable `CutoverInProgress` journal, revalidates inventory and task definitions, disables all six Windows tasks, independently reads back their state, enables the Linux timer, and verifies both sides. Any failure disables the Linux timer and restores exact captured XML and enabled states, followed by independent read-back.

After an interrupted or rolled-back attempt, review the retained evidence and rerun `InstallOrVerifyLinux` before retrying cutover. Repeated stable-state commands are idempotent; drift fails closed.

Explicit rollback remains available:

```powershell
& $tool -Action RestoreLegacy
& $tool -Action Verify
```

## Observation checklist

Keep all six Windows tasks disabled but registered until every item is evidenced:

- [ ] Natural backups complete while WSL is already running.
- [ ] After an explicit `wsl --shutdown`, scheduling does not restart the distro.
- [ ] Windows produces no missed-trigger catch-up storm.
- [ ] Retention completes successfully when its Linux-owned due boundary is reached.
- [ ] Backup and health behavior remain correct across suspend and resume.
- [ ] The retained inventory still validates and an exact rollback remains ready.
- [ ] Prune and full-data-check remain unscheduled pending the Linux-origin request and Windows-visible current-consent bridge.
- [ ] The existing failed full-data-check marker remains unchanged unless a later explicitly consented production full-data check succeeds.

## Delete only after later authorization

`DeleteAfterObservation` is intentionally unavailable without a separately created observation-complete JSON record whose task-set hash matches the retained inventory. Completing this checklist does not itself authorize deletion. Obtain explicit later authorization, create and review that record outside the tool, then invoke the destructive action deliberately.
