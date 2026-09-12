# Repository agent instructions

## Repository-wide boundary

- Relay preparation and execution use machine-local run records and immutable run artifacts. Do not create or edit Relay `draft.md` or `contract.md` files outside an active `/relay` builder.

## Debian bootstrap and managed dotfiles

For changes under `scripts/bootstrap/` or its managed dotfile inputs, run `bash scripts/bootstrap/test-bootstrap.sh` from WSL. Do not run WSL backup tests for those changes.

## WSL backup component

The commands and boundaries below apply only to work under `scripts/wsl-backup/`.

### Commands

Run the smallest test that covers the changed paths. Use mutation tests as targeted strength evidence after changing the protected logic or tests, when test strength is uncertain, or when explicitly requested. Do not run every mutation harness as a routine gate.

| Task | Command |
|---|---|
| Directly affected WSL backup behavior | Run its test under `scripts/wsl-backup/` |
| WSL backup subsystem-wide gate | `bash scripts/wsl-backup/test-all fast` (from WSL) |
| WSL backup integration (requires approval: uses sudo and may query production status) | `bash scripts/wsl-backup/test-all integration` (from WSL) |
| WSL backup PowerShell lint | Use the component fast lane when subsystem-wide lint is warranted; it runs pinned PSScriptAnalyzer 1.25.0 |

### OS ownership boundary

- Routine Restic backup, status, retention, checks, pruning decisions, due state, and serialization belong inside Linux.
- Schedule routine Linux work with Linux `systemd` services/timers. Linux timers run only while the distro is running and may reconcile once when it starts naturally.
- Never create a Windows Scheduled Task, background PowerShell loop, or Windows monitor that invokes `wsl.exe` merely to inspect, poll, schedule, or run routine Linux-owned work.
- A stopped distro cannot have accumulated Linux-side changes. Preserve `wsl --shutdown`; do not wake WSL to discover that nothing changed.
- Windows integration is limited to genuinely Windows-owned boundaries: visible consent UI, AC-power state, temporary idle-sleep inhibition, and whole-distro export. A consented Windows action may enter WSL only to execute the exact approved fixed operation, never for polling.
- Before changing scheduling, classify each operation by owning OS. If Linux can decide and execute it while running, keep both decision and schedule in Linux.

### Production boundaries

- Tests must use disposable repositories, state directories, commands, and scheduler fixtures.
- Do not read or change real Scheduled Tasks, production Restic state, credentials, markers, or deployed files unless the user explicitly authorizes that production action.
- Preserve task definitions for rollback: disable legacy tasks before deleting them, and delete only after the replacement has passed its observation gate.
