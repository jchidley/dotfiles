# Debian4 restored-data reconciliation tasks

Only current incomplete work belongs here. [`STATUS.md`](STATUS.md) records verified state and uncertainty; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequence and approval boundaries.

## Debian4-owned work

1. Review the 141 non-identical or recovered-only boat paths against `/home/jack/boat-data-platform` by content and history. Keep the live repository authoritative and the recovered `17b6592` snapshot inert; propose only selective integrations supported by evidence.
2. Investigate usable history sources for `life-fitness-console` without initializing `.git` in the recovered tree or inventing ancestry.
3. Select authoritative live destinations for unique recovered-material groups. Keep PostgreSQL restore, boat-service installation, and all execution as separate operations.
4. If requested, reconcile private Pi material item by item while preserving session IDs, record identities, branches, variants, wrappers, and source provenance. Do not bulk-import or overwrite active records.
5. Before proposing any deletion, reverify relevant identities and worktrees, confirm current backup coverage, and preserve unique provenance independently. The exact payload-only proposal for the three validated project roots remains in `/home/jack/.local/state/dotfiles-debian4-clone-validation-20260910.md` and requires separate approval.

## Windows-owned work

Windows Pi owns only Windows checkout integrity, current project-record reconciliation, publication after approval, and Windows-side backup references. It must not compare, integrate, delete, or otherwise operate on Debian4 recovered data.

Commit or publish these reconciled records only with the applicable approval.

## Boundaries

- Preserve both native reports under `/home/jack/.local/state/`, every recovered root, and every `.recovery-provenance` directory.
- No recovered path is approved for deletion.
- Deletion, merge, overwrite, database restore, service change, production Restic access, execution, privilege elevation, distro state change, and remote write require explicit approval.
- Keep private material and Pi records out of logs and reports.
