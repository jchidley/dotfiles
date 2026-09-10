# WSL backup and recovery

This directory owns the WSL backup implementation and local operational records. The [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns the immediate objective. Debian4 is the active distro and Windows default. Debian-Recovered, Debian-Backup, Debian2, and Debian3 are retired after completed preservation, recovery assurance, and approved cleanup. The accepted full export and one-off encrypted Restic repository replica are retained on Windows. Historical research and benchmark evidence also live in the `jchidley/tools` WSL backup reference.

Start with [`STATUS.md`](STATUS.md) for dated evidence and [`TASKS.md`](TASKS.md) for current incomplete work. [`RECOVERY-PLAN.md`](RECOVERY-PLAN.md) is now a short historical pointer. Setup and operation examples below describe interfaces, not authorization to change an existing installation.

## Quick start

From the chezmoi source checkout inside WSL:

```bash
cd ~/.local/share/chezmoi
./scripts/wsl-backup/setup.sh
wsl-backup status
```

`setup.sh` is idempotent and non-destructive. It installs or updates the Linux programs, Linux `systemd` scheduler files, and Windows system-export controller, but never enables the timer or registers Windows tasks for routine Linux work. Timer enablement belongs only to the explicit reversible migration in [`home/MIGRATION.md`](home/MIGRATION.md). Setup never creates credentials, initializes a repository, deletes snapshots, or creates a whole-system export.

For a distro whose registered name is not `Debian4`:

```bash
./scripts/wsl-backup/setup.sh --distro NAME
```

## Selected backup design

Use incremental Restic snapshots of `/home/jack` plus a separate complete-distro `wsl --export` tar/gzip without custom exclusions. Restic encryption is an implementation property, not an additional owner requirement. The full export includes plaintext home, credentials and the local repository; no additional archive encryption is required. See the [current contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) and [system candidates](system/README.md). The exclusion-aware archive design is superseded.

## Everyday commands

Run the commands in this section inside WSL. Direct Windows execution requires PowerShell 7 (`pwsh.exe`); Windows PowerShell 5.1 is unsupported.

```bash
# Combined status
wsl-backup status

# Home snapshots
wsl-backup home snapshots
wsl-backup home backup
wsl-backup home check

# Retained controller status (not the new full-export candidate)
wsl-backup system Status
```

The old controller's capture modes are disabled. The accepted full export used the reviewed cold-copy implementation recorded in the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md); do not repeat that production capture merely because the generic installed `wsl-backup system` interface still describes retained controller operations.

Restore home data only into an empty ext4 staging directory:

```bash
wsl-backup home restore latest /var/tmp/restic-home-restore
```

## Components

| Path | Responsibility |
|---|---|
| [`home/`](home/README.md) | Frequent encrypted Restic snapshots, Linux-owned systemd scheduling, retention, checks, and staged restore |
| [`system/`](system/README.md) | Complete-distro export/import source candidates and preserved older archive implementations |
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

Linux-owned scheduler source is integrated at `f41a315`; Windows must not wake or poll WSL for routine Linux work. Historical production state and old-task evidence remain in `STATUS.md`; do not treat them as a live health check.

Fresh Debian4 backup scope follows selected capabilities and data. The old six-task migration and retired Debian3 recovery work are not the immediate queue. The retained Windows Phase 1–3 source is fixture/design evidence, not the routine production scheduler.

## Documentation ownership

- This README and component READMEs: current commands and operational behaviour.
- [`STATUS.md`](STATUS.md): canonical local evidence, current limitations, and historical integration outcomes.
- [`TASKS.md`](TASKS.md): incomplete work only.
- [Debian4 plan](../../docs/DEBIAN4-PLAN.md): current sequence, retained-state decisions, and approval boundaries.
- [`RECOVERY-PLAN.md`](RECOVERY-PLAN.md): historical pointer for the retired Debian3 plan; durable safeguards now live in the Debian4 plan.
- [`LAPTOP-SCHEDULING-PLAN.md`](LAPTOP-SCHEDULING-PLAN.md): historical scheduling design and deferred long-job requirements, not an active deployment plan.
- [`PRODUCTION-HEALTH-STATE-DECISION.md`](PRODUCTION-HEALTH-STATE-DECISION.md): retained policy/fixture acceptance contract; the Windows routine-controller deployment design is superseded.
- Source code and tests: implementation truth.
- `jchidley/tools/docs/wsl-backup.md`: clean cross-repository reference, capability status, and reading path.
- `jchidley/tools/research/2026-08-15-wsl-debian-backup-and-home-recovery.md`: historical recovery evidence, measurements, decisions, and rejected alternatives.
