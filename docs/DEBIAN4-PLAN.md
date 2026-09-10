# Debian4 restored-data reconciliation plan

## Objective

Continue native Debian4 restored-data reconciliation after successful local clone validation, preserving unique material and requiring evidence and separate approval before any integration or deletion.

All restored-data work belongs to native Pi on Debian4. Windows Pi owns only Windows checkout/record integrity, approved publication, and Windows-side backup references.

## Sources of truth

- [`scripts/wsl-backup/STATUS.md`](../scripts/wsl-backup/STATUS.md): current verified state and uncertainty.
- [`scripts/wsl-backup/TASKS.md`](../scripts/wsl-backup/TASKS.md): incomplete work.
- `/home/jack/.local/state/dotfiles-debian4-reconciliation-matrix-20260910.md`: classification and identity evidence for all 16 recovered groups.
- `/home/jack/.local/state/dotfiles-debian4-clone-validation-20260910.md`: successful local validation of three recovered project identities, provenance hashes, and the unexecuted payload-only deletion proposal.
- Provenance manifests within each `/home/jack/recovered-projects/` root.
- [`DEBIAN4-BACKUP-CONTRACT.md`](DEBIAN4-BACKUP-CONTRACT.md): preservation boundaries.

## Verified position

The native clone validation completed from clean dotfiles commit `5697681`. Clean local clones now retain the verified Git identities for `energy-hub`, `octopus-tariff`, and `whatsapp-sqlite-analysis`; `octopus-tariff` has advanced three commits beyond its matching recovered ancestor. Energy Hub's three recorded gitlinks also match without submodule initialization.

The recovered roots and their unique `.recovery-provenance` directories remain intact. No deletion, integration, execution, production backup access, or remote write was performed. The deletion proposal in the native result is not approved and cannot be considered until current backup coverage and identities are reverified.

## Native sequence

1. Compare the divergent recovered boat snapshot with authoritative `/home/jack/boat-data-platform` at path and history level. Propose only selective integration of demonstrated unique value; never replace the live repository wholesale.
2. Investigate `life-fitness-console` history sources without initializing a repository in the recovered tree or fabricating ancestry.
3. Select authoritative live destinations for unique recovered-material groups. Review PostgreSQL through manifests and dump metadata unless restore is separately approved; keep the recovered boat service inert unless installation is approved.
4. Reconcile private Pi material item by item only if requested. Preserve session IDs, record identities, branches, variants, wrappers, and source provenance; never bulk-import or overwrite active records.
5. After each separately approved integration, verify the result independently and update present-tense records.
6. Before seeking approval for any exact deletion, reverify affected source/destination identities and clean worktrees, verify retained provenance, and confirm current backup coverage.

## Windows sequence

Do not perform Debian4 restored-data work from Windows Pi. Windows may reconcile and validate repository records against supplied native results, then present exact commit and publication actions for approval.

## Stopping conditions

Stop a native operation if checkout authority, identity, ancestry, provenance, destination choice, or worktree state differs from recorded evidence. Stop before integration, deletion, restore, installation, service change, production backup access, privilege elevation, distro state change, or remote write unless that exact action has been separately approved.

## Constraints

- Work natively on Debian4 from canonical project roots.
- Preserve worktrees, histories, recovered roots, provenance, branch variants, private modes, and backup artifacts.
- Do not execute recovered code, hooks, scripts, builds, tests, services, databases, or configuration during comparison.
- Never infer duplicate status from names, timestamps, apparent purpose, or similar prose alone.
- Publication and every destructive or external write remain explicit approval boundaries.
