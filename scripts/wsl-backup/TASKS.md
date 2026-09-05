# WSL backup and recovery tasks

Only incomplete work is listed here. Verified inspections, completed migration evidence, and historical source-integration gates live in [`STATUS.md`](STATUS.md). Execute the bounded sequence and acceptance gates in [`RECOVERY-PLAN.md`](RECOVERY-PLAN.md); this queue is not production authorization.

## Immediate recovery work

1. **Owner interaction required:** verify an independently escrowed Restic password unlocks the existing Debian3 repository without using the installed runtime password. Do not expose credentials, automate Bitwarden, regenerate the password, or write confirmation before a successful test and marker-write approval.
2. **Local source work:** adapt and test the existing whole-distro exporter/validator for the inspected Debian3 layout and Linux-owned scheduler. Remove the mandatory legacy-task dependency deliberately; prove disposable-import isolation and retain fail-closed recovery and validation.
3. **Storage, deployment, and downtime approval required:** create a protected Debian3 generation with the reviewed source, verify its manifest/hash, test-import it against the recovery contract, and independently verify cleanup. Preserve existing archives and both fallback distros.

## Before any retirement decision

- Assess unique persistent files/repositories, authentication/configuration, shared PostgreSQL roles, and large objects not covered by the completed table comparison.
- Recheck changing database contents at the retirement boundary; the matching fingerprints were point-in-time evidence, not a permanent synchronization guarantee.
- Confirm ordinary Debian3 use and independently accessible recovery evidence. Then seek separate approval for any exact retirement or PostgreSQL-port change.

## Deferred, not prerequisites for new tooling

- Long-job consent-bridge deployment and prune/full-data-check scheduling remain deferred. Do not clear the historical full-data-check failure marker without separately verified successful full-data-check evidence.
- Do not repeat the completed scheduler cutover or recreate the absent Windows tasks. Legacy migration procedures and earlier fixture work are historical references, not the next action.
- No new experiment trials, probe refactoring, or generalized infrastructure work is queued.
