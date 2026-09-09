# Debian4 completion and selective migration plan

Owner decisions reconciled 5 September 2026. This is the sole active plan for Debian4. It authorizes no secret transfer, forensic recovery, service change, backup initialization, external write, or destructive action by itself.

## Current position

**Debian4 is the clean successor. Debian-Recovered was permanently retired on 9 September 2026 after its preservation reconciliation completed. Debian-Backup remains a temporary extraction/verification source; preserve it and the immutable forensic image until their separately approved retirement.**

The owner selected this remaining order: close out the final recovered findings from the verified Debian4 evidence workspace; complete the Windows-owned full-export and real separate-distro recovery assurance; then separately approve retirement/cleanup and reconcile final documentation. The former Debian-Recovered bundle/old-archive replication is cancelled; optional Debian4 replication is deferred rather than cancelled or added to the current queue. Dirty-state classification is complete: Terminal/retirement and final-recovery records were published separately, the Helix installer was removed without uninstalling Helix, and the full-export candidate plus its mixed working records remain unstaged pending source/documentation integration review. Production cold capture and real recovery under the unique test distro name have completed. The owner explicitly rejected firewall changes and elevated offline-VHD modification as unnecessary; normal boot, actual landmarks, full Restic data check and verified older-snapshot restore passed. Source/documentation integration remains unpublished, and recovered-content review still precedes separately approved cleanup, Debian4 restart and Debian-Backup retirement.

Debian4 already exists and passed its official Debian WSL install and core bootstrap. Do not rebuild it or replay the Debian3 migration. Debian2 and Debian3 have been intentionally unregistered. Their detailed history is not part of the active execution path.

Work from `C:\Users\jackc\git\dotfiles`. On 7 September it was preservation-first fast-forwarded to Debian4's `fc8b1e3`; its pending Windows edits were restored and tree-verified, with the original stash and snapshots retained. Terminal assets were committed separately at `efe87ba`. Keep migration documentation and the unfinished backup candidate separate; never stage or deploy the entire tree as one undifferentiated change.

## Source roles and preservation boundaries

| System | Role | Boundary |
|---|---|---|
| Debian4 | Clean successor and target for selected capabilities/data | Do not import accumulated system state wholesale. |
| Debian-Recovered | Retired source; preservation and migration evidence is historical | Unregistered and local VHDX/backups deleted 9 September 2026 by explicit owner approval. Retain audit evidence only. |
| Debian-Backup | Writable live clone of the immutable August forensic image, for controlled inspection and recovery | Keep stopped except for explicitly planned inspection. Do not compact, optimize, or repair it. The immutable source remains separate. |

Debian-Backup was rebuilt without booting from the read-only August forensic image at `C:\Users\jackc\wsl-recovery-20260802\Debian-ext4-before-recovery.vhdx`. The staged live copy matched its recorded SHA-256 `6d475115d9f214bcaf0093820e095b7989347e65119fcfcad1507999983747e3` before registration. It is registered, writable and stopped at `C:\WSL\Debian-Backup\ext4.vhdx`; its imported default UID is currently root (`0`). Debian-Recovered was the Windows default at that reconstruction checkpoint; the separately approved 7 September cutover subsequently selected Debian4.

Deleted-file recovery can alter metadata or overwrite recoverable blocks in the working clone, but the verified August source remains read-only. Preserve recovered file contents and provenance separately. Earlier recovery lost some date/time metadata, so capture filesystem metadata and recovery-tool evidence before normalizing, importing, or deduplicating recovered Pi sessions.

Debian-Recovered was unregistered and its local VHDX and dedicated Windows backup tree were deleted on 9 September 2026 after explicit owner approval. Debian-Backup, the immutable August source, existing unrelated Restic repositories, and historical audit evidence remain preserved. Debian-Backup retirement still requires a separate verified inventory and explicit approval.

## Completed clean baseline

[Debian4 build results](DEBIAN4-RESULTS.md) record:

- official Debian WSL installation at `C:\WSL\Debian4`, Debian 13.5, default user `jack`;
- core bootstrap from recorded source commits on WSL ext4;
- successful chezmoi apply and offline bootstrap rerun;
- no migrated SSH/GPG credentials, histories, PostgreSQL data, or Restic repository;
- backup timer disabled and no fresh repository initialized;
- remaining source-level gaps listed below.

The [Debian3 comparison](DEBIAN3-RECOVERED-COMPARISON.md) is historical evidence only. It established that Debian-Recovered retained the important authoritative material before Debian3 was intentionally removed.

## Immediate work

**Current source/selection checkpoint — 7 September 2026:** [current tasks](../scripts/wsl-backup/TASKS.md) supersede older pending bootstrap, repository-publication and routing statements below. Windows default-distro and AK routing cutovers are recorded complete; no new credential audit was performed in this source review. Bootstrap/Rust work is committed through `300d46a`, with managed-job guidance at `fc8b1e3`; no additional deployment occurred. Fresh backups remain blocked on the deferred storage/password choices. The [Debian4 backup contract](DEBIAN4-BACKUP-CONTRACT.md) records proposed coverage, concrete candidate defects and restore gates. PostgreSQL remains undecided.

**Earlier selective-data checkpoint — 7 September 2026:** the information-superset migration preserved and installed Debian-Recovered's unique boat-data-platform checkout (including 19 local-ahead commits), recovered heatpump checkout, exact `ak` delta, McFly/Bash histories, SSH identity bytes, and selected small historical state. Source bundles/tars and verification are under `C:\Users\jackc\wsl-recovery-20260802\debian4-superset-migration-20260907T000000Z`. Debian4 contains and can decrypt all 14 expected AK services with its new identity; approved Windows/WSL routing now targets Debian4 and all managed lookups pass (`8556708`). Source/value equality and passphrase-protected SSH use still require private interaction. Reconcile heatpump authority, protect boat commits, disposition the `ak` patch, complete reproducible bootstrap gaps, and establish fresh restore-tested backups before retirement.

**Pi execution checkpoint — 6 September 2026:** the approved Pi import is complete under `debian4-import-execution-20260906T112532Z`. All 905 native files and 2,826 archive payload files were published without overwrites or skips; separate destination verification and controller review passed. Execution evidence is sealed across 24 files. Two failed launch attempts remain preserved; the successful worker ignored HUP before fork and isolated its session before Node startup. Retain staging, fixtures, archive and all sources; no cleanup or retirement is authorized. All distros were stopped at final review, with Debian-Recovered still default. Continue only the separately scoped remaining bootstrap/data/credential/backup work in [current tasks](../scripts/wsl-backup/TASKS.md). The preparation checkpoint below is historical.

**Historical preparation checkpoint — 6 September 2026 UTC:** the approved built-in pass, bounded specialist attempt, and offline evidence curation have completed. Use the [inspection handoff](DEBIAN-BACKUP-INSPECTION.md) and [current tasks](../scripts/wsl-backup/TASKS.md) to review `pi-corpus-curation-20260905T234252Z-v2`, its unresolved gaps, and its exact Debian4 import preview. Do not replay the historical forensic sequence below. The subsequently approved `debian4-import-preflight-20260906T002855Z` passed with no source delta or target conflicts and sufficient guest/host storage. Transfer preparation is now complete under `debian4-transfer-preparation-20260906T005124Z`: 20 ext4 scenarios, seven refresh-guard tests, three detected semantic faults, and detached-job status checks passed. Its `IMPORT-PROCEDURE.md` proposes the unchanged 905 native files plus 2,826 archive payload files, retained independent staging, exclusive publication and separate destination verification. Final owner approval remains required before the fixed launcher refreshes the narrow checks and imports; staging/rollback deletion is a separate approval. No import has occurred.

### Recovery authorization — 5 September 2026

The owner explicitly approved the following recovery sequence after review of the current-corpus reconciliation:

1. analyse the 21 session IDs absent from Debian-Recovered's current corpus and all 24 preserved carved variants; validate JSON, record and parent chains, compare variants, prefer stronger independent provenance where available, and create separately marked human-readable derivatives without replacing recovered bytes;
2. elevate as required to attach only the prepared working VHDX through Hyper-V read-only/no-drive-letter and expose it to WSL as a bare device; identify it from observed before/after metadata, prove it remains read-only and unmounted, capture live and deleted Pi-related ext4 directory/inode/extent/journal evidence, recover selected bytes only into the prepared evidence directory, detach it, and verify all boundaries;
3. stream-scan that observed read-only guest block device for complete, fragmented or truncated Pi JSON records and transcripts, recording guest logical offsets and reconciling results with the prior physical-VHDX scan;
4. if material gaps remain, install and use only the reviewed `ext4magic` and Sleuth Kit recovery tooling in a separate recovery environment against additional disposable image copies, preserving each tool's output separately; and
5. curate a lossless final corpus that keeps originals, variants, conflicts and synthetic derivatives distinct, then preview exact Debian4 destinations and conflict handling.

This authorization does not include mounting any filesystem, attaching the immutable source, starting or altering Debian-Backup, repairing or replaying the filesystem journal, discard/TRIM, importing into Debian4, deleting evidence or sources, exposing secret values, changing services/routing, or initializing backups. Package installation is limited to the named recovery tools in a separate recovery environment after exact package-source, version and command review; it must not modify Debian-Backup. Debian4 import remains a later preview-and-approval operation.

### 1. Inventory Debian-Backup and recover deleted records

The immutable source and verified writable clone now exist. The [offline inspection procedure](DEBIAN-BACKUP-INSPECTION.md) uses a disposable copy of the immutable image and leaves the registered Debian-Backup stopped. That working copy was created, hash-verified, and left writable, unregistered, and unmounted at `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\working\ext4.vhdx`; its `copy-manifest.json` is beside the `working` and `evidence` directories. Current nonsecret source evidence is recorded in the [source inventory](DEBIAN4-SOURCE-INVENTORY.md). Before inspection:

1. Confirm Debian-Backup remains stopped, the immutable August source remains read-only, and the prepared copy remains unregistered/unmounted. The copy phase already passed these checks.
2. Inventory available tools and preview the exact bare-attachment, read-only inspection, evidence-write, detach, and failure-cleanup commands. The owner subsequently approved the reviewed recovery sequence above; execution must still fail closed if its documented preconditions or read-only guarantees are not met. Starting the registered clone can overwrite deleted blocks within it and is not part of this pass.
3. Inventory live files and attempt deleted Pi-session recovery from an explicitly selected working image.
4. Record original paths, recovered bytes, inode/deletion metadata and tool output. Do not infer trustworthy timestamps where metadata was already lost.
5. Compare recovered Pi records by stable content and internal session metadata, not filesystem timestamps alone. Preserve collisions and uncertain provenance rather than overwriting.
6. Keep both source distros until selected current and deleted data is represented in Debian4 or protected recovery evidence.

Mounting an image, running recovery tools, transferring recovered data, or removing a source remains a concrete approval boundary.

### 2. Select Debian4 capabilities and personal data

Use Debian-Recovered and the protected Debian-Backup evidence to make a finite selection. Current candidates:

- **Pi sessions/transcripts:** wanted. Include older sessions recovered from Debian-Backup. Preserve exact-cwd association, content, and provenance; do not bulk rewrite paths or overwrite collisions.
- **McFly/Bash history:** likely wanted. Transfer SQLite consistently and merge divergent history deliberately.
- **SSH identity:** select separately from authoritative Debian-Recovered.
- **AK credentials:** selected design below.
- **Git repositories:** rebuild public repositories from reviewed upstream state; separately preserve uncommitted, unpushed, ignored, local-only, or deleted work found in either source.
- **PostgreSQL/boat data:** undecided. Debian-Recovered remains the preserved source. Decide whether Debian4 needs a service, dumps only, or reproducible rebuild support from actual workflow evidence.
- **Pi/OpenAI login:** not a preservation requirement; authenticate again when needed.
- **Existing Restic history:** retain with the surviving system it backs up. Do not transplant it to initialize Debian4.

For every selected transfer: preview exact source, destination, conflict behavior, and effects; preserve target rollback state; perform a consistent transfer; verify independently; and leave the source intact.

### 3. Bootstrap gap history

The required McFly/web-search/Pi-guidance and Rust/bootstrap corrections below were subsequently integrated; use the current checkpoint/tasks rather than replaying them. Optional editors and historical home-content selection still depend on actual workflow requirements.

Original review list:

1. Install the tools required by managed configuration and machine policy—at minimum resolve Git's configured `gh`, `delta`, and editor dependencies, plus the `uv`/`uvx` Python policy and declared `rg` workflow.
2. Make a fresh first login initialize Bash/McFly history without warnings; do not import history merely to hide the defect.
3. Replace the stale `~/bin/web-search` target with the supported agent-skills entrypoint.
4. Reconcile the committed Pi `AGENTS.md` template with the current machine-owned guidance; remove stale completion language without weakening approval boundaries.
5. Resolve the ShellCheck finding in `scripts/bootstrap/migrate-ak-secrets.sh` and complete the bootstrap test suite. The repository-only SC2015 repair now passes the retained test; deployment remains separate.
6. Decide whether Helix/Neovim and other hinted tools are actual requirements rather than installing every mentioned program.
7. Review historical committed home content before treating it as part of the clean profile.

Keep these changes separate from the paused backup implementation candidate. Test source changes before applying them selectively to Debian4.

### 4. AK identity and transfer history

The new identity, selected credential population and routing cutover are recorded complete in the later checkpoints. Do not replay initialization or transfer. Exact equality to the locked source and independently protected recovery remain separate checks. The original sequence below is retained as history; `Copy-WslAkSecrets.ps1` copies the old identity and was not suitable unchanged.

1. Select the required AK service names from Debian-Recovered without exposing values.
2. Inspect existing Debian4 target state before initialization.
3. Run the bootstrap interactively so it creates the standard passphrase-protected GPG identity and selects it with `ak init`; passphrase entry remains private and interactive.
4. Validate the transfer implementation with disposable keys and values.
5. With concrete approval for the exact service list, decrypt each selected value on Debian-Recovered and stream it directly into encryption for Debian4's new recipient. Plaintext must not enter files, arguments, environment variables, logs, or agent output.
6. Check both sides' exit status, preserve rollback state, and verify Debian4 decryption without printing values or fingerprints.
7. Establish protected recovery for the new private key and passphrase before relying on it.
8. Leave Debian-Recovered and the Windows AK route unchanged until any separately approved cutover.

### 5. Establish fresh Debian4 backups after selection

**Local home portion completed — 7 September 2026:** later owner authorization selected durable local Restic for accidental-erasure recovery, with whole-distro export explicitly separate. The pinned repository, private recovery-password verification, full data check/verified restore, Linux timer cadence and owner-driven shutdown/restart observation passed. See [current backup status](../scripts/wsl-backup/STATUS.md). The original sequence below is retained for the remaining broader backup work; it must not be replayed to regenerate the enrolled credential or repository. Source retirement still requires separate approval.

Follow the [Debian4 backup contract](DEBIAN4-BACKUP-CONTRACT.md), which records the reviewed candidate defects and missing prerequisites. Only after Debian4's capabilities and data are selected:

1. Define backup contents and restore landmarks from Debian4's chosen system, including selected Pi/McFly recovery data and PostgreSQL only if chosen.
2. Retain Linux/systemd ownership of routine scheduling. Windows may handle consent UI, AC power, temporary idle-sleep inhibition, and whole-distro export, but must not poll or wake WSL for routine Linux work.
3. Review and complete the preserved backup candidate without inheriting Debian3-specific landmarks.
4. Choose an explicitly new repository and protected independent storage. Never initialize over an existing repository or regenerate an existing password.
5. Establish independently recoverable credentials, create the first snapshot, and restore-test it before enabling scheduling.
6. Validate whole-distro export through an isolated disposable import before relying on it. Agree secret-bearing contents, storage, downtime, final source state, and cleanup in advance.
7. Record whether storage protects against loss of the distro and the laptop; same-disk storage does not.

## Completion gates

Debian4 becomes the daily successor only when:

- required tools and normal login workflows pass from reproducible source;
- selected current and recovered personal data is transferred with provenance and conflict checks;
- selected credentials work and have independent recovery;
- the first fresh backup and restore test pass;
- routine scheduling is explicitly enabled only afterward.

No remaining distro retirement, default-distro change, Windows AK route change, PostgreSQL activation, secret transfer, forensic operation, or backup deployment is implied by this plan.
