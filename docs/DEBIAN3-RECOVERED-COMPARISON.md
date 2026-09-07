# Historical evidence — Debian3 versus Debian-Recovered, 5 September 2026

> **Non-operational record:** Debian3 was subsequently unregistered by explicit owner authorization. Do not use this report as an active migration, preservation, service, or backup plan. Current work is governed by the [Debian4 plan](DEBIAN4-PLAN.md).

This was the authorized read-only content/provenance follow-up to the [Debian4 results](DEBIAN4-RESULTS.md). **No important unique Debian3 application data was identified that required retaining it as a whole.** It was not byte-for-byte contained in Debian-Recovered, but the observed history differences and migration artifacts were expected, not evidence that the authoritative source was bad. This was not an exhaustive filesystem audit. Debian-Recovered remains the owner's authoritative, known-good source.

## Scope and method

Debian3 was restarted for the approved comparison; Debian-Recovered was already running. Enabled Debian3 services may run naturally. No manual backup, database write, service change, secret retrieval, migration or deletion was performed.

Compared relative paths and SHA-256 contents for selected personal histories and recovery files: Pi sessions, Pi transcripts, `~/recovery`, McFly database files and `.bash_history`. Digests were retained only in local comparison evidence, not printed into the report. Credential files were excluded from content hashing and examined only by metadata. Repository HEADs, local branch state and working-tree filenames were inspected with optional Git locks disabled; no fetch or synchronization was performed.

This is a point-in-time, selected-data comparison, not a full-filesystem or atomic cross-distro snapshot. Live files may change. McFly checks used read-only immutable SQLite connections; no WAL/SHM sidecars were present at the check. No history entries, database rows or auth-file contents were printed.

## Content results

| Selected data | Result |
|---|---|
| Pi sessions | **860 paths, all byte-identical**, no unique paths in either selected tree |
| Pi transcripts | **27 paths, all byte-identical**, no unique paths in either selected tree |
| Older recovery files | **69 paths byte-identical** |
| PostgreSQL recovery artifacts under `~/recovery` | **Four Debian3-only paths**: `postgresql-20260904T232427Z/{roles.sql,boatdata_direct.dump,boatdata_staging.dump,SHA256SUMS}` |
| Bash history | Same path, different contents; individual commands were not inspected |
| McFly live database | Different file and logical SQLite dump; Debian-Recovered **176** command rows, Debian3 **186** |
| McFly recovery database | Different file and logical SQLite dump; Debian-Recovered **176** command rows, Debian3 **186** |

All four McFly database files passed `PRAGMA integrity_check`. The difference is not merely SQLite file layout: the logical dumps differ too. Ten more rows does **not** prove Debian3 contains every Debian-Recovered row; a row-level merge decision remains separate. Likewise, the four PostgreSQL files are unique **within the selected home recovery tree**; this does not assert that equivalent backups exist nowhere else.

## Repositories and other source state

Debian-Recovered has additional discovered Git checkouts absent from Debian3's bounded inventory:

- `~/boat-data-platform`
- `~/projects/heatpump-analysis`
- `~/git/symphony`
- `~/git/agent-state-backup`
- `~/git/mkdocs-material-test`

Repository discovery searched `.git` directories to depth five under home. It does not exhaustively detect `.git` files, deeper worktrees, ignored work, or non-Git projects.

The boat checkout is at `d18e28dfa02cde135a5536bbb5dc85d6632ad7db`, with cached tracking reporting ahead 19. This is not a fresh remote comparison. Preserve local history; do not assume a remote already has it.

Debian-Recovered's AK checkout has a modified `services/spider.yaml`; Debian3's is clean at the same commit. Only the changed pathname was recorded; its contents were not opened or copied.

Shared repository HEADs differ except AK:

| Repository | Debian-Recovered | Debian3 |
|---|---|---|
| dotfiles / chezmoi | `05710ea` | `ad8ec45` |
| agent-skills | `766d921` | `e6b85bd` |
| ak | `7c53208` plus local edit | `7c53208`, clean |
| tools | `7e65d2b` | `42c1089` |

Debian3's agent-skills and tools inventories list no local branch refs; do not assume every clean checkout is on `main`. None was changed. Different revisions are evidence of differing working snapshots, not proof that Git objects or commits are absent from the other repository's complete object database.

## Credentials, databases and Restic: bounded uncertainty

- Both systems have SSH/GPG metadata and Pi auth files. Same SSH key size/mode/timestamp does not prove key identity. Auth-file sizes differ. No credential values or credential fingerprints were read or compared.
- Debian3 PostgreSQL 17 is online at 5432; Debian-Recovered's is down. This inspection did not restart the source database, query either database, or repeat the earlier logical-content comparison. Post-cutover database divergence remains unresolved.
- `/var/lib/restic` is root-owned mode 700 on both systems. The unprivileged probe cannot determine whether `/var/lib/restic/home` exists beneath it. **An inaccessible child is not an absent repository.**
- Reinspection of migration session `01a06e20-7135-75c8-af5d-495ff8ed30c8` shows the successful Restic transfer used source `tar` streaming and destination `cp -a`. The destination commit step ran explicitly in Debian3, with rollback state at `/var/lib/dotfiles-migration/restic-before-20260904T232427Z`. It copied the source repository/configuration/password and changed Debian3's backup host. Those commands do **not** remove the source Restic repository. The source timer was disabled separately.
- Therefore the original operation is evidenced as a **copy plus scheduler cutover**, not a demonstrated source-repository move. This corrects any inference drawn from the word “migration.” Its current protected-path disposition still needs privileged read-only inspection; no claim is made that subsequent actions could not have changed it.

## Disposition for Debian4

1. Pi histories have a verified duplicate source at this checkpoint. Choose one deliberately; no need to concatenate identical copies.
2. Preserve both Bash/McFly histories until a selected, consistent merge is designed and verified. Do not overwrite one merely because the other has more entries.
3. Preserve Debian3's PostgreSQL recovery artifacts and both database clusters; decide the laptop database requirement from boat-workflow evidence.
4. Preserve Debian-Recovered's extra repositories, local branch history and AK edit. Rebuild reproducible dependencies from source, not old binaries.
5. Keep existing Restic history associated with its source/provenance. Do not initialize, move, prune or delete repositories to reconcile this inventory.

The owner subsequently approved privileged read-only Restic metadata inspection; results follow below. Later decisions removed Debian3 PostgreSQL divergence and Pi/OpenAI login from the preservation question. Debian-Recovered's authoritative credential inventory was checked directly, as recorded below. Byte-for-byte equivalence of credentials or current databases is not a prerequisite selected by the owner.

## Privileged Restic metadata follow-up — 09:32 UTC

After explicit owner approval, Debian3 was restarted and the two named distros were inspected using `sudo -n` for `stat`, `find` and `du` only. No Restic command, password-file read, content hash, maintenance operation or configuration change was performed. Debian3's enabled services could run naturally after startup.

**Debian-Recovered's original repository still exists.** The earlier inaccessible-path uncertainty is resolved; absence must not be inferred from the unprivileged probe.

| `/var/lib/restic/home` metadata | Debian-Recovered | Debian3 |
|---|---:|---:|
| Repository and config present | Yes | Yes |
| Snapshot files | 234 | 238 |
| Data files | 921 | 935 |
| Index files | 806 | 810 |
| Key files | 1 | 1 |
| Lock files at inspection | 0 | 0 |
| Allocated bytes (`du -sx -B1`) | 1,077,760,000 | 1,217,482,752 |

Both repository directories are root-owned mode 700; their config files are root-owned mode 400. File counts are storage metadata, not decrypted snapshot validation. No cross-repository content/subset assertion follows from the counts, and zero lock files is only a point-in-time observation.

Debian3 retains `/var/lib/dotfiles-migration/restic-before-20260904T232427Z/`, root-owned mode 700, with `etc-restic` and `var-lib-restic` rollback directories. Its `var-lib-restic/home` is absent: this rollback is prior target configuration/state, not another full inherited Restic repository. Debian-Recovered has no `/var/lib/dotfiles-migration` directory. The known transfer stage `/var/tmp/debian3-restic-20260904T232427Z` is absent on both.

Together with the historical source `tar` and destination `cp -a` evidence, the result supports **source repository preserved, copy established in Debian3, then separate target activity**. Preserve both histories. No relocation or reinitialization is needed merely to correct the earlier uncertainty. Integrity, credential recovery and exact snapshot overlap were not tested by this metadata-only operation.

## Authoritative-source clarification and credential check — 09:40 UTC

The owner clarified that **Debian2 was not authoritative**. Direct inspection of Debian-Recovered verified:

- `~/.config/ak/vault.conf` routes locally to Debian-Recovered; the AK command resolves to `~/git/ak/bin/ak` at `7c53208`.
- SSH Ed25519 private/public files are jack-owned mode 600, with a mode-700 SSH directory. The public fingerprint matches the previously recorded identity. No private-key derivation/decryption was attempted.
- GPG recognizes the configured secret primary key and encryption subkey, both locally available; both corresponding private-key files exist. The GPG directories are mode 700 and key-file permission checks passed.
- 14 nonempty encrypted AK files, no insecure owner/permission findings; all ten managed export-allowlist services have stored encrypted files. The additional stored services include Spider, SSH passphrase, Together and ZAI. Declared services without a stored value are not automatically missing requirements.
- No secret values were retrieved, no credential fingerprints were computed, and no route or credential file was changed. GPG key visibility is not a new decryption or API-acceptance test.

No identified credential gap requires using Debian3 as the source. The owner's selected target design is a **new GPG identity on Debian4**, with selected existing credentials re-encrypted from Debian-Recovered, not a copy of Debian2/3's identity. This has not been executed; see the [active plan](DEBIAN4-PLAN.md).

## PostgreSQL preservation decision

The owner is not concerned about newer PostgreSQL state on Debian3. The question is whether the authoritative Debian-Recovered source was harmed. Reinspection of the cutover's actual tool calls confirms it ran `systemctl disable --now postgresql.service` and stopped the cluster service on Debian-Recovered, then verified it down. It did **not** change that system's port, replace/restore the database, or delete database files. Debian3 alone was changed from port 5433 to 5432. Debian-Recovered remains configured for 5432.

Normal shutdown can write database state, so earlier wording that database files were literally “unchanged” was too strong. Successful earlier source dumps/comparisons plus the reviewed shutdown commands provide no identified evidence of source damage; they are not a fresh offline integrity test. Do not reopen Debian3 divergence as a blocker, or install PostgreSQL on Debian4 before choosing that capability.

## Practical preservation decision

The owner considers the Pi/OpenAI login disposable. Pi sessions/transcripts and old recovery files have identical copies on Debian-Recovered. McFly/Bash differences reflect independent activity; the additional PostgreSQL dump files are explained migration artifacts. They can be retained separately if wanted. Existing Restic history remains with both systems and does not need transplanting into Debian4.

At the time of this comparison, no deletion was authorized. In the subsequent session, the owner explicitly authorized permanent Debian3 removal with no new export after the comparison had found no important unique application data requiring whole-distro retention. Preflight found Debian3 stopped at `C:\WSL\Debian3` with no active export/import client. `wsl.exe --unregister Debian3` succeeded, and independent registry/path checks confirmed its registration and storage directory absent. The deleted VHDX included Debian3-local copies and differences described above; Debian-Recovered remains the authoritative source. The proportionate next work remains selected Debian4 capability/credential/history setup, not repeated strict-superset proof.

## Local evidence

`C:\Users\jackc\AppData\Local\DotfilesComparisons\Debian3-Recovered-20260905-101911\` contains selected-file inventories, path dispositions (`comparison.json`), repository/path metadata and non-content McFly comparison evidence. Source-system files were not written; only this Windows evidence directory and repository documentation were created/updated. This is a comparison record, not a backup or deletion authorization.
