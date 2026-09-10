# Debian4 recovered-data reconciliation tasks

Only current incomplete work belongs here. [`STATUS.md`](STATUS.md) records verified state and uncertainty; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequence and approval boundaries; the [backup contract](../../docs/DEBIAN4-BACKUP-CONTRACT.md) owns backup and recovery constraints.

## Current priority

1. Compare the four retained private Pi recovery roots with active `~/.pi` read-only. Classify each item as an exact duplicate, complete import candidate, conflicting variant, or incomplete/provenance-only evidence. Produce an exact no-overwrite import preview and stop for owner approval before any active-state write.
2. After explicit approval, import only unambiguous complete items while preserving session IDs, associations, branches, wrappers, and provenance. Validate the result and report every unresolved item with a recommended next action; never bulk-import or overwrite active sessions.

Boat tests, selective integrations, and PostgreSQL restoration are owned by separate boat project operations, not this task list.

## Preservation boundaries

- Preserve the matrix, clone-validation record, boat review, superseded local-only life-fitness search, destination report, and `/home/jack/.local/state/dotfiles-debian4-github-destination-follow-up-20260910.md` as evidence.
- Preserve the three unique ignored children under `~/git/boat-data-platform/recovered/` and unrelated work until a reviewed operation explicitly changes them. All redundant recovered roots are intentionally absent following owner-authorized cleanup.
- Do not execute recovered content, initialize replacement repositories, invent ancestry, flatten Pi variants, infer duplicates from names, or run the superseded `/home/jack/.pi/next/dotfiles-debian4-0856.md` handoff.
- Deletion, overwrite, merge, database restore, service change, production Restic access, privilege elevation, publication, and other external writes require explicit approval.
