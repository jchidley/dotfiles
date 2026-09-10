# Debian4 native restored-data reconciliation plan

## Objective

Enable native Pi work on Debian4 to compare all restored data with existing data, retain unique material, and remove verified duplicates safely.

This plan authorizes read-only local comparison and reporting. It does not authorize deletion, overwrite, merge, database restore, service installation, production backup operation, privilege elevation, remote write, or publication.

## Sources of truth

- [`scripts/wsl-backup/STATUS.md`](../scripts/wsl-backup/STATUS.md): current verified state and uncertainty.
- [`scripts/wsl-backup/TASKS.md`](../scripts/wsl-backup/TASKS.md): incomplete work only.
- Native matrix `/home/jack/.local/state/dotfiles-debian4-reconciliation-matrix-20260910.md`: per-group comparison evidence and current disposition proposals.
- [`DEBIAN4-BACKUP-CONTRACT.md`](DEBIAN4-BACKUP-CONTRACT.md): backup, recovery, and preservation boundaries.
- Provenance directories within each promoted tree: source commit/file identity and retained manifests.
- Git repositories and current files inside Debian4: implementation and live-data truth, subject to worktree preservation.

Dated build, source-inventory, inspection, and recovery-result documents are historical evidence, not current execution plans.

## Current decisions

- Preserve all 16 recovered groups; the current exact deletion preview is empty.
- Keep `/home/jack/boat-data-platform` authoritative for live boat work and retain the divergent recovered `17b6592` tree for focused path-level review.
- Retain `life-fitness-console` as unique until usable history can be found or reconstructed without invention.
- Treat all recovered-material groups as locally unique. Keep personal material private; database restore and service installation remain separate operations.
- Preserve the complete Pi corpus and wrappers because they contain absent records, variants, and unique provenance despite partial active-history duplication.

## Sequence

1. Reconcile the clean native dotfiles checkout with the authoritative Windows branch through reviewed Git commit/push/fast-forward operations. Stop if either worktree changes or diverges.
2. With explicit approval, clone the remotes for `energy-hub`, `octopus-tariff`, and `whatsapp-sqlite-analysis` into new `/home/jack/git/` paths. Verify recovered commit/tree ancestry and submodule identities against those local repositories; execute no project content.
3. Preserve recovery provenance independently of payload duplication, then prepare a new exact deletion preview for any remote-retained recovered project roots. Verify current backup coverage before asking to delete them.
4. Compare the 141 non-identical/recovered-only boat paths semantically and by history. Propose selective integration only where unique value is established; never replace the live repository wholesale.
5. Investigate `life-fitness-console` history sources without initializing `.git` in the recovered tree or fabricating ancestry.
6. Select authoritative live destinations for unique recovered-material groups. Review PostgreSQL only through manifests/dump metadata unless restore is approved; keep the boat service inert unless installation is approved.
7. Reconcile Pi recovery at item level only if the owner wants active-session integration. Preserve session IDs, record identities, branches, variants, and wrapper provenance; never bulk-import or overwrite active sessions.
8. After each approved integration, verify independently, update present-tense records, confirm backup coverage, and request separate approval for exact deletions.

## Stopping condition

For the next bounded operation, stop after the three approved local clones and identity revalidation produce a provenance-preservation and deletion proposal. Stop earlier if checkout authority, remote identity, submodule identity, or native worktree state differs from the matrix.

## Constraints

- Work natively on Debian4 from canonical project roots.
- Preserve worktrees, untracked files, histories, remotes, provenance, branch variants, and private modes.
- Do not execute recovered code, hooks, scripts, services, databases, or configuration during comparison.
- Never infer duplicate status from names, timestamps, apparent purpose, or similar prose alone.
- Do not recreate retired forensic evidence or repeat completed export/recovery assurance.
- Deletion, overwrite, merge, database restore, service change, production Restic access, distro stop/restart, privilege elevation, publication, and other external writes require explicit approval.
