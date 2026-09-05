# Debian3 recovery assurance plan

This is the active bounded plan: establish independently recoverable Debian3 backups before considering retirement of Debian-Recovered or Debian-Backup. It is not authority to export, deploy, retrieve secrets, clear markers, or retire a distro. Current evidence belongs in [`STATUS.md`](STATUS.md); incomplete work belongs in [`TASKS.md`](TASKS.md).

## Starting position

The 5 September inspection verified migrated recovery landmarks, retained Restic backup/check/restore records, and matching boat-database table content, sequence state, and normalized schemas. These are point-in-time results, not proof of independent password recovery or whole-distro recovery. The escrow confirmation marker is absent. No validated Debian3 export is evidenced in the inspected default storage.

Debian3's Linux timer is enabled; no legacy Windows Restic tasks exist. The installed source checkouts differ from the canonical Windows source. Do not synchronize or deploy them implicitly. At final inventory Debian3 and Debian-Backup were stopped, Debian-Recovered was running; do not infer current runtime state from that snapshot.

## 1. Independent password recovery

- Have the owner retrieve the escrowed Restic password through a trusted interactive workflow. Do not automate Bitwarden, print the password, or place it in commands, logs, Git, or session output.
- Prepare a narrowly reviewed unlock test that uses the supplied recovery value, not the installed runtime password. Explicitly select the Debian3 repository and prevent fallback to runtime credentials.
- Stop if the value is unavailable or incorrect; do not regenerate the runtime password or initialize the existing repository.
- Record a confirmation marker only after a successful independent unlock test and explicit authorization for that marker write.

**Gate:** independently supplied recovery credentials demonstrably unlock the existing repository; retain only nonsecret test evidence.

## 2. Narrow whole-distro source adaptation

Reuse `system/Backup-WslSystem.ps1`, its common helpers, validator, and disposable tests. This is not a new backup framework or scheduling project.

- Replace the mandatory six-task assumption with an explicit reviewed Debian3/Linux-owned-scheduler path. Do not silently ignore unexpected legacy tasks or recreate tasks to satisfy validation.
- Preserve cold-export consistency, overlap refusal, crash recovery, failed-artifact handling, validated-generation promotion, manifest/hash checks, and distro-scoped retention. Preserve all existing Debian-Recovered generations.
- Define the source running/stopped-state contract before execution. A deliberately stopped source must not be started merely for routine polling. If the source is running, plan PostgreSQL/service quiescence and the approved downtime explicitly rather than assuming a filesystem sync proves database shutdown.
- Bind the validator to the inspected Debian3 layout: user/ownership, SSH permissions, Pi sessions/transcripts, McFly integrity, installed tools and foundation repositories, encrypted AK/GPG metadata, retained PostgreSQL dumps, databases, and included Restic repository. Do not reuse the absent `~/boat-data-platform` landmark or incidental file-count thresholds as the recovery contract.
- Validate sensitive material without printing or decrypting it unless a separate test explicitly requires owner approval. Independent password recovery remains a separate gate.
- Before starting a disposable import, prevent its timer, PostgreSQL, and other recovered services from contacting or conflicting with production. The isolation mechanism must be demonstrated, not inferred from a random distro name.
- Test absent/unexpected tasks, source-state preservation, malformed evidence, interrupted/failed export, validator rejection, promotion only after success, cleanup restricted to the disposable import, and preservation of other distro generations.

**Gate:** focused disposable regression tests and the canonical `test-all fast` lane pass from the exact source checkout. Any integration lane with production status access needs its stated authorization. Source validation is not deployment approval.

## 3. Approved protected export and restore validation

Before executing, obtain agreement on:

- the exact archive and temporary-import locations, protection at rest/access controls, available space, and eventual retention;
- the secret-bearing contents: SSH/GPG keys, credentials, databases, and local backup history;
- the maintenance window, services affected, source final state, and narrowly scoped deployment of reviewed files;
- the disposable import's isolation and cleanup procedure.

Use the approved existing exporter after adaptation. Verify archive size and SHA-256 manifest, import into the isolated disposable target, and run the agreed recovery checks. Record durable nonsecret evidence and independently verify cleanup. Do not promote a failed validation or delete preserved recovery copies to make space.

**Gate:** a protected Debian3 generation exists and its independently imported contents pass the agreed recovery contract. A same-disk archive alone does not protect against loss of the laptop; state that limitation unless independent storage is actually verified.

## 4. Retirement decision — separate later work

- Inventory remaining unique files and repositories, authentication/configuration, shared PostgreSQL roles, and large objects not covered by the table comparison. Preserve unresolved material rather than silently treating it as redundant.
- Recheck database changes at the retirement boundary: the earlier comparison was not cross-distro atomic and neither database was made permanently read-only.
- Confirm normal Debian3 workflows and recovery access without relying on Debian-Recovered. Treat any database-port change separately.
- Present the recovery evidence and exact proposed retirement action for explicit approval. Do not unregister either preserved distro under this plan's implementation or inspection authority.

## Deferred work

No new experiment trials, probe refactoring, generalized infrastructure, Windows polling scheduler, consent-bridge rollout, prune/full-data-check scheduling, or distro retirement is part of this immediate objective. The historical failed full-data-check marker was not revalidated here; do not clear it based on a structural check or latest-snapshot restore. The old scheduling design remains in [`LAPTOP-SCHEDULING-PLAN.md`](LAPTOP-SCHEDULING-PLAN.md), not in the active queue.
