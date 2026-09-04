# Repository agent instructions

## Commands

| Task | Command |
|---|---|
| Fast, side-effect-free gate | `./scripts/wsl-backup/test-all fast` (from WSL) |
| Disposable Restic integration | `./scripts/wsl-backup/test-all integration` (from WSL) |
| PowerShell lint | Use the canonical fast lane; it runs pinned PSScriptAnalyzer 1.25.0 |

## OS ownership boundary

- Routine Restic backup, status, retention, checks, pruning decisions, due state, and serialization belong inside Linux.
- Schedule routine Linux work with Linux `systemd` services/timers. Linux timers run only while the distro is running and may reconcile once when it starts naturally.
- Never create a Windows Scheduled Task, background PowerShell loop, or Windows monitor that invokes `wsl.exe` merely to inspect, poll, schedule, or run routine Linux-owned work.
- A stopped distro cannot have accumulated Linux-side changes. Preserve `wsl --shutdown`; do not wake WSL to discover that nothing changed.
- Windows integration is limited to genuinely Windows-owned boundaries: visible consent UI, AC-power state, temporary idle-sleep inhibition, and whole-distro export. A consented Windows action may enter WSL only to execute the exact approved fixed operation, never for polling.
- Before changing scheduling, classify each operation by owning OS. If Linux can decide and execute it while running, keep both decision and schedule in Linux.

## Production boundaries

- Tests must use disposable repositories, state directories, commands, and scheduler fixtures.
- Do not read or change real Scheduled Tasks, production Restic state, credentials, markers, or deployed files unless the user explicitly authorizes that production action.
- Preserve task definitions for rollback: disable legacy tasks before deleting them, and delete only after the replacement has passed its observation gate.
- `NEXT-SESSION.md` is relay-owned metadata; do not modify it outside an active `/relay` builder.
