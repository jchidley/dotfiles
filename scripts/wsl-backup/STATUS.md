# Debian4 restored-data reconciliation status

This file records current operational truth and uncertainty. [`TASKS.md`](TASKS.md) owns incomplete work; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequence and approval boundaries; Git history retains completed backup/recovery detail.

## Current position

Debian4 owns all remaining restored-data work. Windows Pi retains only Windows checkout/record coordination, approved publication, and Windows-side backup references.

The native read-only matrix at `/home/jack/.local/state/dotfiles-debian4-reconciliation-matrix-20260910.md` classifies all 16 recovered groups. The subsequent clone validation at `/home/jack/.local/state/dotfiles-debian4-clone-validation-20260910.md` completed successfully from a clean native dotfiles checkout at `5697681`.

The Windows checkout remains aligned with `origin/main` at `5697681`; these three canonical records are modified only to reconcile that completed native result.

## Completed clone validation

Three new native checkouts are clean and aligned with their origin tracking branches:

- `/home/jack/git/energy-hub` is at remote `main` commit `b107a21`; its recovered commit and tree match HEAD. All 59 blobs and the three recorded gitlinks match exactly. No submodule was initialized.
- `/home/jack/git/octopus-tariff` is at remote `master` commit `a63c8a0`; recovered commit `dad7f0f` and its tree match locally, and that commit is an ancestor of HEAD by three commits.
- `/home/jack/git/whatsapp-sqlite-analysis` is at remote `main` commit `9fc0b97`; its recovered commit and tree match HEAD.

Only ordinary read-only Git clone traffic was used. No recovered or cloned content, hooks, builds, tests, scripts, services, databases, configuration, submodules, production backup state, or remote state were executed or changed.

Each recovered root remains preserved. Its `.recovery-provenance` directory is unique and must survive any later approved payload cleanup. The native result contains an exact payload-only deletion proposal, but no deletion is approved; current backup coverage and identities must first be reverified.

## Remaining reconciliation state

- Keep `/home/jack/boat-data-platform` authoritative and retain the divergent recovered `17b6592` tree pending focused path-level review.
- Retain `life-fitness-console` as unique because no counterpart or usable history is currently available.
- Treat every recovered-material group as locally unique until an authoritative destination is selected. PostgreSQL restore and boat-service installation remain separate operations.
- Preserve the complete private Pi corpus and wrappers because they contain absent records, variants, and unique provenance.
- No recovered path is approved for deletion.

## Protection and runtime

- Accepted full export: `C:/WSL-Backups/Debian4/full/20260909T170315Z-091d2190/`.
- Encrypted Windows-side Restic replica: `C:/WSL-Backups/Debian4/restic/20260910T000023Z-6090f188/`.
- Debian4 was running with its Linux timer enabled at the latest verified observation. Runtime and backup freshness are volatile and must be rechecked only when relevant and approved.
