# Debian4 recovered-data reconciliation status

This file records current operational truth and uncertainty. [`TASKS.md`](TASKS.md) owns incomplete work; the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequence and approval boundaries; Git history retains completed backup and recovery detail.

## Current position

Debian4 is the active platform for native Pi reconciliation. The canonical dotfiles checkout is based on `5697681`, aligned with `origin/main` before the current record reconciliation.

The native comparison matrix is `/home/jack/.local/state/dotfiles-debian4-reconciliation-matrix-20260910.md`. Completed clone/identity results are in `/home/jack/.local/state/dotfiles-debian4-clone-validation-20260910.md`; the completed boat review is `/home/jack/.local/state/dotfiles-debian4-boat-selective-integration-proposal-20260910.md`; the completed local life-fitness history search is `/home/jack/.local/state/dotfiles-debian4-life-fitness-history-search-20260910.md`. The recovered roots remain protected; no merge, import, restore, installation, or cleanup is approved.

## Verified disposition

- Native clean checkouts exist for `energy-hub`, `octopus-tariff`, and `whatsapp-sqlite-analysis`. Their recovered commit/tree identities match retained Git history as recorded in the clone-validation report. Their recovered roots still hold provenance that must survive any payload cleanup.
- The boat review reproduced all 185 manifest hashes and the 44 exact / 43 differing / 98 recovered-only path counts. Of the 141 non-identical paths, 65 exact recovered blobs are reachable from live repository refs and 76 are not. Four selective candidates are recorded: MasterBus importer safeguards, the navigation consumer contract, a conditional boat-time redesign, and a three-PGN regression seed. The live repository remains authoritative and the complete recovered `17b6592` snapshot remains inert.
- The completed local `life-fitness-console` search is accepted. Its mode-`0700` recovered snapshot still reproduces all 412 recorded SHA-256 values and contains no `.git`; no legitimate retained history source was found. Provenance retains no superproject origin URL. Two unavailable/private name-based remote leads remain optional and require approval for authenticated access; neither is identity evidence.
- Every group under `/home/jack/recovered-material/` remains unique in the bounded comparison and lacks a selected authoritative destination. PostgreSQL package hashes verify internally; no database is restored.
- The private Pi recovery corpus contains retained-history overlap plus absent records, branch variants, wrappers, and unique provenance. Active-session reconciliation is optional and cannot be a bulk import.

## Validation and cleanup readiness

The canonical fast gate passes its Linux setup/CLI, scheduler, and semantic-mutation stages, then fails when Windows execution policy rejects the unsigned PowerShell test script. Treat the full gate as incomplete until that policy interaction is diagnosed separately; do not bypass or weaken policy as part of recovered-data work.

The payload-only proposal for the three Git-retained project roots is in the clone-validation report. It is a proposal, not an authorization. Before any deletion, revalidate repository identities and worktrees, verify provenance hashes, and confirm current backup coverage. Current backup coverage after the latest recovered-data state is not established by these records.

## Remaining uncertainty

- Whether and when to authorize any of the four boat integration candidates; none is approved by the review.
- Whether the owner later wants an approval-required authenticated read-only check of the two weak `life-fitness-console` remote leads; this is not required for the accepted local disposition.
- The authoritative destination and safe integration method for each unique recovered-material group.
- Whether the owner wants private Pi records reconciled into active storage.
