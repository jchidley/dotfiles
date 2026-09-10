# Debian4 recovered-data reconciliation tasks

Only current incomplete work belongs here. [`STATUS.md`](STATUS.md) records verified state and uncertainty; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequence and approval boundaries; the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) owns backup and recovery constraints.

## Current priority

1. Diagnose the recorded boat test failures in a separate project session from physical checkout `/home/jack/git/boat-data-platform`, after reading that repository's `AGENTS.md`, `docs/development.md`, and `docs/operations.md`. Revalidate the absent-`rsync` prerequisite separately from the undefined-`stderr` defect with targeted tests. Stop before package installation, sudo, deployment, service/database action, or push without approval; do not edit boat code from this dotfiles session.
2. Only if the owner wants it, reconcile private Pi material item by item while preserving session IDs, branches, variants, wrappers, and provenance. Do not bulk-import or overwrite active sessions.
3. If the owner authorizes boat integration or PostgreSQL restore, use the retained boat review and treat each action as a separate design/test operation. Do not merge, execute, or delete material under `~/git/boat-data-platform/recovered/` or deploy recovered content as part of reconciliation.

## Preservation boundaries

- Preserve the matrix, clone-validation record, boat review, superseded local-only life-fitness search, destination report, and `/home/jack/.local/state/dotfiles-debian4-github-destination-follow-up-20260910.md` as evidence.
- Preserve the three unique ignored children under `~/git/boat-data-platform/recovered/` and unrelated work until a reviewed operation explicitly changes them. All redundant recovered roots are intentionally absent following owner-authorized cleanup.
- Do not execute recovered content, initialize replacement repositories, invent ancestry, flatten Pi variants, infer duplicates from names, or run the superseded `/home/jack/.pi/next/dotfiles-debian4-0856.md` handoff.
- Deletion, overwrite, merge, database restore, service change, production Restic access, privilege elevation, publication, and other external writes require explicit approval.
