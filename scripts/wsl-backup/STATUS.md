# Debian4 restored-data reconciliation status

This file records current operational truth and uncertainty. [`TASKS.md`](TASKS.md) owns incomplete work; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequence and approval boundaries; Git history retains completed backup/recovery detail.

## Current position

Debian4 is the active WSL distro and the platform for native Pi reconciliation. A native read-only pass classified all 16 recovered groups without executing or modifying recovered payloads, repositories, sessions, databases, services, backups, or remotes. Its disposition matrix is `/home/jack/.local/state/dotfiles-debian4-reconciliation-matrix-20260910.md`.

The native dotfiles checkout is clean at `6154bde`, eight commits behind verified remote `e8b2b0f` and nine commits behind Windows `26f14b5`. It is stale but contains no divergent commit. The Windows checkout contains the authoritative current records and one unpublished closeout commit. Synchronization must use reviewed Git operations rather than copying or resetting either worktree.

## Reconciliation result

- All five `/home/jack/recovered-projects/` roots remain mode 0700, inert, without `.git`, and match their provenance manifests.
- `energy-hub` and `whatsapp-sqlite-analysis` exactly match commits retained by their remotes; `octopus-tariff` matches a retained ancestor. None has a native local checkout, so recovered roots remain the only local copies and retain unique provenance.
- `boat-data-platform-hourly-log` is divergent from live `/home/jack/boat-data-platform`: 44 matching paths are exact, 43 differ, 98 are recovered-only, and 660 are live-only. The live repository remains authoritative; the recovered snapshot remains the authoritative `17b6592` variant.
- `life-fitness-console` has no available local or remote counterpart. Its complete recovered snapshot remains unique.
- Every group under `/home/jack/recovered-material/` has no exact payload counterpart elsewhere in the bounded Debian4 comparison. PostgreSQL package hashes verify; no database was contacted.
- The private Pi recovery corpus contains active-history duplication plus absent session IDs, missing records, branch variants, and unique association/wrapper provenance. It is not safe to flatten or bulk-import.

The exact deletion preview is empty. No recovered path is currently safe to delete.

## Protection and runtime

- Accepted full export: `C:/WSL-Backups/Debian4/full/20260909T170315Z-091d2190/`.
- Encrypted Windows-side Restic repository replica: `C:/WSL-Backups/Debian4/restic/20260910T000023Z-6090f188/`.
- The replica is outside Debian4's VHDX but remains on the same physical disk.
- Debian4 was running by owner decision with its Linux backup timer enabled and service idle at the latest verified observation. Recheck volatile runtime and backup state rather than assuming them.

## Next approval boundary

The next useful bounded operation is to clone `energy-hub`, `octopus-tariff`, and `whatsapp-sqlite-analysis` into new `/home/jack/git/` destinations, then reverify recovered identities locally. It authorizes no merge, overwrite, deletion, database restore, service change, production backup access, remote write, or publication unless separately confirmed.
