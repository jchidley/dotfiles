# Debian4 recovered-data reconciliation plan

## Objective

Resolve the remaining recovered-data dispositions while keeping live repositories authoritative and recovered snapshots inert.

This plan authorizes read-only local comparison and reporting. It does not authorize deletion, overwrite, merge, database restore, service installation, production backup operation, privilege elevation, remote write, or publication.

## Sources of truth

- [`scripts/wsl-backup/STATUS.md`](../scripts/wsl-backup/STATUS.md): current verified state and uncertainty.
- [`scripts/wsl-backup/TASKS.md`](../scripts/wsl-backup/TASKS.md): incomplete work only.
- Native matrix `/home/jack/.local/state/dotfiles-debian4-reconciliation-matrix-20260910.md`: per-group comparison evidence and disposition proposals.
- Clone validation `/home/jack/.local/state/dotfiles-debian4-clone-validation-20260910.md`: local repository identities and payload-only cleanup proposal.
- Boat review `/home/jack/.local/state/dotfiles-debian4-boat-selective-integration-proposal-20260910.md`: path/hash/history evidence and bounded integration candidates.
- Life-fitness history search `/home/jack/.local/state/dotfiles-debian4-life-fitness-history-search-20260910.md`: verified snapshot identity, bounded local-source search, and remote approval boundary.
- Recovered-material destination proposals `/home/jack/.local/state/dotfiles-debian4-recovered-material-destination-proposals-20260910.md`: protected archival destinations and inert retention methods.
- Authenticated GitHub follow-up `/home/jack/.local/state/dotfiles-debian4-github-destination-follow-up-20260910.md`: exact `life_cycle` identity, new `celnav` and `research` checkouts, destination corrections, and the owner’s Symphony discard decision.
- [`DEBIAN4-BACKUP-CONTRACT.md`](DEBIAN4-BACKUP-CONTRACT.md): backup, recovery, and preservation boundaries.
- Provenance directories within each recovered tree: source commit/file identity and retained manifests.
- Current Git repositories and files inside Debian4: implementation and live-data truth, subject to worktree preservation.

Dated build, inventory, inspection, recovery, and session records are historical evidence, not current instructions.

## Current decisions

- `/home/jack/git/boat-data-platform` is the canonical physical checkout; `/home/jack/boat-data-platform` is a compatibility symlink for intentional local and target-host path references. The divergent `17b6592` snapshot, retired-service archive, and PostgreSQL package each have one visible home under the checkout’s ignored `recovered/` directory. Directories use normal mode `0755`; regular PostgreSQL package files use mode `0644`.
- The authenticated follow-up supersedes the local-only `life-fitness-console` disposition: clean `/home/jack/git/life_cycle` is the exact recovered commit/tree authority. Its duplicate recovered root and temporary provenance copy are deleted.
- All seven celestial forms/variants are published in `jchidley/celnav` at `8e96795`; both recovered notes are published in `jchidley/research` at `6ba358d` with machine-specific SMB identifiers generalized. Their redundant recovered roots and provenance are deleted.
- The Git-retained `energy-hub`, `octopus-tariff`, and `whatsapp-sqlite-analysis` recovered roots are deleted after exact commit/tree revalidation. The verified PostgreSQL boat-data package has one protected home at `/home/jack/git/boat-data-platform/recovered/postgresql-boatdata`. The Symphony prototype root is deleted.
- Reconcile private Pi material only if the owner opts in, item by item, preserving session IDs, branches, variants, wrappers, and provenance.
- Redundant project/material cleanup is complete under the owner’s explicit no-duplicate direction. The remaining boat roots are unique and are not deletion candidates.

## Sequence

1. The eight approved OneDrive files are complete and hash-verified; their redundant recovered roots and temporary provenance copies are deleted.
2. Keep the three ignored recovered boat groups inert under the boat project. Selective integration, database restore, service installation, or retirement remains separately approval-required.
3. In a separate bounded operation, diagnose the Windows PowerShell execution-policy rejection in the canonical fast gate. Do not weaken policy or elevate merely to make the test pass.
4. Only with explicit owner approval, restore PostgreSQL, reconcile private Pi material, or pursue any boat integration candidate.

## Stopping condition

Owner-directed placement, redundant-copy cleanup, and publication of boat consolidation commit `5758ab8` are complete. Stop before changing recovered boat material, restoring PostgreSQL, installing services, or integrating private Pi/boat material.

## Constraints

- Work natively on Debian4 from canonical project roots.
- Preserve unrelated work, worktrees, untracked files, histories, remotes, recovered roots, provenance, branch variants, wrappers, and private modes.
- Do not execute recovered code, hooks, scripts, services, databases, or configuration during comparison.
- Never infer identity or duplicate status from names, timestamps, apparent purpose, or similar prose alone.
- Do not recreate retired forensic evidence, repeat completed recovery assurance, or execute the superseded `/home/jack/.pi/next/dotfiles-debian4-0856.md` handoff.
- Deletion, overwrite, merge, database restore, service change, production Restic access, distro stop/restart, privilege elevation, publication, and other external writes require explicit approval.
