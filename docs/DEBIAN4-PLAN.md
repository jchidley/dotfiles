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
- [`DEBIAN4-BACKUP-CONTRACT.md`](DEBIAN4-BACKUP-CONTRACT.md): backup, recovery, and preservation boundaries.
- Provenance directories within each recovered tree: source commit/file identity and retained manifests.
- Current Git repositories and files inside Debian4: implementation and live-data truth, subject to worktree preservation.

Dated build, inventory, inspection, recovery, and session records are historical evidence, not current instructions.

## Current decisions

- Keep `/home/jack/boat-data-platform` authoritative for live boat work and retain the recovered `17b6592` tree as an inert variant. Consider only the four selective integration candidates in the boat-review record; none is approved for merge or deployment.
- Accept the completed local `life-fitness-console` search and keep the recovered snapshot unique and inert. Its provenance retains no superproject origin URL. The two weak remote leads are optional follow-up only and require owner approval for authenticated access; do not initialize Git in the recovered tree or invent ancestry.
- Keep all recovered-material groups protected until each has an authoritative destination. PostgreSQL restoration and boat-service installation are separate approval-required operations.
- Reconcile private Pi material only if the owner opts in, item by item, preserving session IDs, branches, variants, wrappers, and provenance.
- The payload-only cleanup proposal is not approved for execution. Any cleanup requires fresh identity, worktree, provenance-hash, and backup-coverage checks followed by separate explicit approval.

## Sequence

1. Choose an authoritative destination and proposed inert transfer or integration method for each unique group under `/home/jack/recovered-material/`. Keep PostgreSQL restoration and boat-service installation outside this operation.
2. In a separate bounded operation, diagnose the Windows PowerShell execution-policy rejection in the canonical fast gate before treating that gate as complete. Do not weaken policy or elevate merely to make the test pass.
3. Only with explicit owner approval, pursue optional work: authenticated checks of the two weak life-fitness remote leads, item-level private Pi reconciliation, or any of the four boat integration candidates.
4. Before requesting cleanup approval, revalidate relevant repository identities and worktrees, verify retained provenance hashes, and confirm current backup coverage. Review the exact payload-only proposal in the clone-validation record and stop before deletion.

## Stopping condition

For the next bounded operation, stop after authoritative destinations and inert transfer/integration proposals are recorded for the unique recovered-material groups. Stop earlier if identity, provenance, privacy, worktree, or destination-authority assumptions differ from retained evidence. Do not restore databases, install services, execute recovered content, or move material.

## Constraints

- Work natively on Debian4 from canonical project roots.
- Preserve unrelated work, worktrees, untracked files, histories, remotes, recovered roots, provenance, branch variants, wrappers, and private modes.
- Do not execute recovered code, hooks, scripts, services, databases, or configuration during comparison.
- Never infer identity or duplicate status from names, timestamps, apparent purpose, or similar prose alone.
- Do not recreate retired forensic evidence, repeat completed recovery assurance, or execute the superseded `/home/jack/.pi/next/dotfiles-debian4-0856.md` handoff.
- Deletion, overwrite, merge, database restore, service change, production Restic access, distro stop/restart, privilege elevation, publication, and other external writes require explicit approval.
