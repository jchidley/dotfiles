# Debian4 recovered-data reconciliation tasks

Only current incomplete work belongs here. [`STATUS.md`](STATUS.md) records verified state and uncertainty; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequence and approval boundaries; the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) owns backup and recovery constraints.

## Current priority

1. Choose an authoritative destination for each unique group under `/home/jack/recovered-material/`. Produce proposals only; do not move, execute, restore, install, or delete material. Keep PostgreSQL restoration and boat-service installation as separate approval-required operations.
2. Separately diagnose why Windows execution policy rejects the unsigned PowerShell test script in `bash scripts/wsl-backup/test-all fast`. Do not elevate, change policy, or bypass signing controls without explicit approval.
3. Only with owner approval, perform authenticated read-only checks of the two weak life-fitness remote leads recorded in `/home/jack/.local/state/dotfiles-debian4-life-fitness-history-search-20260910.md`.
4. Only if the owner wants it, reconcile private Pi material item by item while preserving session IDs, branches, variants, wrappers, and provenance. Do not bulk-import or overwrite active sessions.
5. If the owner authorizes boat integration work, use `/home/jack/.local/state/dotfiles-debian4-boat-selective-integration-proposal-20260910.md` and treat each candidate as a separate current-main design/test operation. Do not merge the recovered tree or deploy recovered content.
6. Before proposing any cleanup execution, revalidate identities and worktrees, verify provenance hashes, and confirm current backup coverage. Use `/home/jack/.local/state/dotfiles-debian4-clone-validation-20260910.md` as the payload-only proposal. Obtain separate explicit approval before deletion.

## Preservation boundaries

- Preserve the matrix, clone-validation record, boat review, and `/home/jack/.local/state/dotfiles-debian4-life-fitness-history-search-20260910.md` as evidence.
- Preserve all recovered roots and unrelated work until a reviewed operation explicitly changes them.
- Do not execute recovered content, initialize replacement repositories, invent ancestry, flatten Pi variants, infer duplicates from names, or run the superseded `/home/jack/.pi/next/dotfiles-debian4-0856.md` handoff.
- Deletion, overwrite, merge, database restore, service change, production Restic access, privilege elevation, publication, and other external writes require explicit approval.
