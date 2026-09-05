# WSL backup and recovery

This directory owns the WSL backup implementation and local operational records. Debian3 is the recovery-assurance target; Debian-Recovered and Debian-Backup remain preserved recovery sources. Historical research and benchmark evidence also live in the `jchidley/tools` WSL backup reference.

Start with [`STATUS.md`](STATUS.md) for verified evidence, [`TASKS.md`](TASKS.md) for incomplete work, and [`RECOVERY-PLAN.md`](RECOVERY-PLAN.md) for the active bounded plan. Setup and operation examples below describe interfaces, not authorization to change an existing installation. Debian3's whole-system export path still needs adaptation; do not run the legacy export examples against it unchanged.

## Quick start

From the chezmoi source checkout inside WSL:

```bash
cd ~/.local/share/chezmoi
./scripts/wsl-backup/setup.sh
wsl-backup status
```

`setup.sh` is idempotent and non-destructive. It installs or updates the Linux programs, Linux `systemd` scheduler files, and Windows system-export controller, but never enables the timer or registers Windows tasks for routine Linux work. Timer enablement belongs only to the explicit reversible migration in [`home/MIGRATION.md`](home/MIGRATION.md). Setup never creates credentials, initializes a repository, deletes snapshots, or creates a whole-system export.

For a distro whose registered name is not `Debian-Recovered`:

```bash
./scripts/wsl-backup/setup.sh --distro NAME
```

## Everyday commands

Run the commands in this section inside WSL. Direct Windows execution requires PowerShell 7 (`pwsh.exe`); Windows PowerShell 5.1 is unsupported.

```bash
# Combined status
wsl-backup status

# Home snapshots
wsl-backup home snapshots
wsl-backup home backup
wsl-backup home check

# Whole-system operations
wsl-backup system Preflight
wsl-backup system Status
wsl-backup system Export -ConfirmMaintenanceWindow
```

Whole-system export stops the source distro. It remains protected by the explicit `-ConfirmMaintenanceWindow` gate.

Restore home data only into an empty ext4 staging directory:

```bash
wsl-backup home restore latest /var/tmp/restic-home-restore
```

## Components

| Path | Responsibility |
|---|---|
| [`home/`](home/README.md) | Frequent encrypted Restic snapshots, Linux-owned systemd scheduling, retention, checks, and staged restore |
| [`system/`](system/README.md) | Cold complete-distro export, disposable-import validation, manifests, retention, crash recovery, and cleanup |
| `setup.sh` | Non-destructive Linux installation/timer setup plus whole-system Windows integration |
| `wsl-backup` | Installed operator command for home and system operations |
| `Install-Windows.ps1` | Installs the system-export controller outside the distro so it remains available while the source is stopped |

## Initialization boundary

A fresh machine needs a separately escrowed Restic password and explicit repository initialization. Setup intentionally stops before this security boundary. Follow [`home/README.md`](home/README.md#initialize-explicitly) and test the Bitwarden recovery value. Scheduling is enabled only through the reviewed migration after its preflight passes.

## Validation

Run the unified test command inside WSL:

```bash
./scripts/wsl-backup/test-all fast         # static analysis and disposable component/contract tests
./scripts/wsl-backup/test-all integration  # real disposable Restic fixture and production status smoke test
./scripts/wsl-backup/test-all all          # both lanes
```

The fast lane does not modify production repositories or tasks. It covers isolated Linux scheduler/setup, command dispatch and exit propagation, retained legacy-task policy, notification suppression, manifest/task helpers, Bash syntax, ShellCheck, and PSScriptAnalyzer under PowerShell 7. The integration lane creates and removes a disposable Restic repository under `/var/tmp`; its production interaction is read-only status inspection.

See [`TESTING.md`](TESTING.md) for stable contracts, mutation evidence, and explicitly deferred scope.

## Scheduling and recovery status

Linux-owned scheduler source is integrated at `f41a315`; Windows must not wake or poll WSL for routine Linux work. The 5 September inspection verified Debian3's enabled timer, Debian-Recovered's disabled timer, and zero legacy Windows Restic tasks. See `STATUS.md` for timestamps and limits rather than treating this summary as a live health check.

Independent password recovery and a validated Debian3 whole-distro backup remain open. The old six-task migration is not the next action; follow `RECOVERY-PLAN.md`. The retained Windows Phase 1–3 source is fixture/design evidence, not the routine production scheduler.

## Documentation ownership

- This README and component READMEs: current commands and operational behaviour.
- [`STATUS.md`](STATUS.md): canonical local evidence, current limitations, and historical integration outcomes.
- [`TASKS.md`](TASKS.md): incomplete work only.
- [`RECOVERY-PLAN.md`](RECOVERY-PLAN.md): active bounded recovery objective, sequence, approval boundaries, and acceptance gates.
- [`LAPTOP-SCHEDULING-PLAN.md`](LAPTOP-SCHEDULING-PLAN.md): historical scheduling design and deferred long-job requirements, not an active deployment plan.
- [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md): retained policy/fixture acceptance contract; the Windows routine-controller deployment design is superseded.
- Source code and tests: implementation truth.
- `jchidley/tools/docs/wsl-backup.md`: clean cross-repository reference, capability status, and reading path.
- `jchidley/tools/research/2026-08-15-wsl-debian-backup-and-home-recovery.md`: historical recovery evidence, measurements, decisions, and rejected alternatives.
