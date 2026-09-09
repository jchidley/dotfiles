# Debian4 clean-build results — 5 September 2026

## Post-import entry point — 7 September 2026

The Pi recovery/import is complete; do not rerun the importer. Current migration,
cutover, retained-source boundaries and remaining backup prerequisites are in
[`scripts/wsl-backup/STATUS.md`](../scripts/wsl-backup/STATUS.md) and
[`scripts/wsl-backup/TASKS.md`](../scripts/wsl-backup/TASKS.md), governed by the
[active plan](DEBIAN4-PLAN.md). Read those before acting. The dated clean-build
and comparison narrative below is historical, including its earlier default
routing, missing tools, and absence of migrated personal data; it is not a
current migration checklist. Recovery completion does not complete or approve
backup deployment, restore validation, scheduling, or source retirement.

## Original clean-build evidence

Execution evidence for the [Debian4 plan](DEBIAN4-PLAN.md). The owner authorized the official clean install, bootstrap, and comparison. **Debian4 was built and the bootstrap completed; it is not yet a fully validated daily-use successor.** No selected personal-data migration or service cutover has occurred.

## Session closeout — governing decisions

The [active plan](DEBIAN4-PLAN.md) owns next actions: extract useful current and recoverable data from Debian-Recovered and Debian-Backup, repair the reproducible baseline, then define and test fresh Debian4 backups. Debian4's clean baseline exists; do not rebuild it or replay an old migration.

Subsequent checks confirmed Debian-Recovered's original Restic repository and authoritative SSH/GPG/AK material remain present. Debian-Recovered is the known-good source and Windows default. Debian-Backup is now a stopped writable clone of the protected August forensic image for controlled inspection and recovery. The [Debian3 comparison report](DEBIAN3-RECOVERED-COMPARISON.md) is non-operational historical evidence. Debian2 and Debian3 were subsequently retired.

The selected AK direction is **new GPG key on Debian4, selected existing credentials re-encrypted from Debian-Recovered**. No key generation, secret transfer, API-key rotation or Windows AK route change has occurred.

A later, separately requested Windows Terminal change is complete: Debian4 uses the exact recovered Debian2 red swirl; Debian2/Debian3 Terminal entries were removed, not merely hidden. That Terminal-only action did not delete distros; Debian3 was removed later through the separately authorized action recorded below. See [Terminal configuration](windows-terminal.md) for source assets, deployed paths, backups, verification and WSL regeneration caveat. This supersedes the earlier build-stage statement that Terminal was untouched, not the clean-build evidence itself.

All new documentation/assets and the earlier unfinished backup changes remain local and uncommitted. HEAD remains the earlier `1e2915f` documentation commit. A later continuation made repository-only fixes for the McFly first-login history file, web-search launcher, Pi guidance template, and migration-helper ShellCheck finding; the retained bootstrap test passes. None has been deployed to Debian4, and the larger tool-installation gap remains open.

## Prepared offline inspection copy

On 5 September, the owner approved creating a separate working copy for the filesystem-aware August-image inspection. The immutable source and completed copy both matched SHA-256 `6d475115d9f214bcaf0093820e095b7989347e65119fcfcad1507999983747e3` and length 149,704,146,944 bytes. The operation completed at `2026-09-05T12:43:12Z` after 21 minutes 25 seconds.

- Working copy: `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\working\ext4.vhdx`
- Evidence destination: `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\evidence\`
- Operation record: `C:\Users\jackc\wsl-recovery-20260802\debian-backup-inspection-20260905T120500Z\copy-manifest.json`

The source remained read-only. The working copy is writable, unregistered and unmounted; the temporary partial file is absent. Debian-Backup remained stopped. No image was attached or mounted, no recovery tool ran, and no recovered data was imported. The next session must inventory already-installed tools and present exact fail-closed attachment, inspection, output, detach and cleanup commands before seeking approval to execute them.

## Subsequent Debian3 retirement

On the next session, the owner explicitly confirmed permanent removal of Debian3 after a read-only preflight. Debian3 was stopped, registered at `C:\WSL\Debian3`, and had no active export/import client. `wsl.exe --unregister Debian3` completed successfully; independent checks then confirmed the registration and `C:\WSL\Debian3` storage directory absent. Debian2 was already unregistered. No new Debian3 export was made; its distro-local copied Restic history, additional McFly history and PostgreSQL recovery files were deleted with the VHDX as expressly confirmed. Debian-Recovered, Debian4 and Debian-Backup were not targeted. Registration inventories later in this report are historical checkpoints.

The owner then discarded the unneeded September pre-rename VHDX and authorized rebuilding live Debian-Backup from the preserved August forensic image. A staged copy matched SHA-256 `6d475115d9f214bcaf0093820e095b7989347e65119fcfcad1507999983747e3` before registration. Debian-Backup is now a stopped, writable clone at `C:\WSL\Debian-Backup\ext4.vhdx`; it was not booted, and its imported default UID is `0`. The August source remains read-only. Debian-Recovered was set as the Windows default distro. Both source distros are retained only until useful current/deleted data is extracted into Debian4 and independent recovery is established; eventual removals remain separate approvals.

## Subsequent Debian-Recovered retirement

On 9 September 2026, after preservation reconciliation completed, the owner explicitly approved permanent removal. `wsl.exe --unregister Debian-Recovered` completed; independent checks confirmed its registration and 43.6 GB `C:\Users\jackc\wsl-recovery-20260802\Debian-Recovered` storage absent. The dedicated 1.38 GB `C:\WSL-Backups\Debian-Recovered` backup tree and both current and legacy Windows Terminal profile identities were removed. Debian-Recovery-Tools, Debian-Backup, the immutable August forensic VHDX, and historical audit/evidence were retained as explicitly directed. Earlier references below to Debian-Recovered being retained or authoritative are historical checkpoints.

## Installation and inputs

Official installation command, executed from canonical Windows dotfiles:

```powershell
wsl.exe --install Debian --name Debian4 --location C:\WSL\Debian4 --version 2 --no-launch
```

WSL reported successful installation; independent registry inspection confirmed the unique Debian4 registration at `C:\WSL\Debian4`. `/etc/os-release` and `/etc/debian_version` identify Debian 13.5 (trixie). This is the official online WSL installation route, not the cached rootfs builder or a clone of an existing VHDX. The resulting Debian release happens to match the earlier rootfs release; a different delivery route does not imply a different Debian version.

Created normal user `jack`, UID/GID 1000, home `/home/jack`, shell Bash, member of `sudo`. Configured default user through WSL management and `/etc/wsl.conf`; independent default-user invocation returned `jack`. Used the existing builder's explicit passwordless-sudo policy in `/etc/sudoers.d/90-jack`, validated by `visudo`. No login password was generated. The official image already sets `[boot] systemd=true`; it was preserved, with only the default-user section appended.

Bootstrap executed on Debian4 ext4 in `/home/jack/.local/share/chezmoi`, profile `dev`, group `foundation` (`core`). Sources were the latest GitHub revisions checked at preparation:

| Repository | Exact commit | Source transport |
|---|---|---|
| dotfiles / chezmoi source | `1e2915f10a5f52a9cf1a7fb7ab9559c552453e5a` | Fresh public GitHub clone |
| ak | `7c53208f1b48109d8db1b6ed191131d00872c18f` | Fresh public GitHub clone |
| agent-skills | `67253425dd6d304cbd1aa3df9dc10268608ea00a` | Verified committed-source Git bundle from Windows |
| tools | `42c10893f78ea81d2ad5b57248cbb864b73cc257` | Verified committed-source Git bundle from Windows |

All four target checkouts are clean on `main` with GitHub remotes and `origin/main` tracking. Bundle tips were checked against the approved revisions and `git fsck` passed. No Windows working-tree edits, installed dependencies, runtime credentials, or histories were transferred. In particular, the unfinished backup candidate was excluded; an unrelated Windows tools documentation edit was also excluded.

The initial `agent-skills` HTTPS clone stalled; bounded Linux remote probes also timed out, including HTTP/1.1, while dotfiles queries worked. Only its identified clone processes were terminated; the wrapper recorded exit 143. A subsequent tools clone reached its explicit 180-second timeout (exit 124). Partial target directories were preserved if present. The source bundle route was announced rather than silently substituting older checkouts. Direct fresh Linux GitHub cloning of those two repositories therefore remains a transport issue, not a proven clean-room download success.

An initial Linux-detached preparation attempt never opened its log and left no process. Setup was run through a detached Windows WSL client executing a fixed Linux script, with durable Linux exit markers. Preparation, final bootstrap installation and offline rerun each completed with exit 0. No build/clone processes remained at final inspection.

## Installed baseline and validation

| Item | Result |
|---|---|
| Debian / PID 1 | Debian 13.5 / systemd |
| Default user / home ownership | jack, 1000:1000; no non-jack-owned paths found under the new home |
| Node / npm | 22.19.0 / 10.9.3 |
| Pi | 0.85.0; CLI/version and package discovery passed; authenticated model use untested |
| fnm / McFly | 1.38.1 / 0.9.4 |
| chezmoi | 2.69.4 |
| Source and installed repositories | Four selected exact revisions; clean; ext4 |
| Managed configuration | Full pre-apply diff reviewed; apply passed; final `chezmoi status` empty |
| Offline bootstrap rerun | Passed with `BOOTSTRAP_OFFLINE=1`, `SKIP_SYSTEM_PACKAGES=1`, `APPLY_CHEZMOI=1`, host integration disabled |
| Interactive login check | Pseudo-terminal Bash login found native Node/npm/Pi/fnm/McFly/chezmoi and Pi package; warnings below remain |
| Package inventory | 240 installed package records captured |
| Backup scheduler | Unit installed, disabled/inactive; no password or initialized Restic repository |
| Personal state | Zero Pi sessions/transcripts, zero SSH/GPG private keys; no Pi auth, recovery directory or PostgreSQL data |
| Bootstrap PowerShell tests | Passed |
| Retained Bash bootstrap suite | **Failed at ShellCheck 0.10.0 SC2015**, `scripts/bootstrap/migrate-ak-secrets.sh:34`; suite did not complete |

The offline option proves cached bootstrap artifacts and rerun behavior with system package installation skipped. It is not a network-isolated reproduction of the initial apt/npm installation. Pi CLI/model availability warnings occurred without configured authentication; no API request or credential retrieval was used to validate it.

### Concrete clean-baseline gaps

1. **Git dependencies:** managed Git configuration selects `gh`, `delta` and `nvim`, but none is installed by core bootstrap. Public clones succeeded for some sources without authentication, which does not validate authenticated Git use.
2. **Other workflow tools:** `uv`, `uvx`, `rg`, `fd` and `hx` were absent on the tested native PATH. Some are referenced by guidance or shell hints. Decide actual requirements and install reproducibly rather than copying old binaries.
3. **McFly first login:** emits “`.bash_history` does not exist or is not readable.” Binary checks pass, but history initialization is not a clean first-login success. This requires source-level first-run handling, not importing old history to hide it.
4. **Backup defaults:** installed nonsecret configuration says `BACKUP_HOST=Debian-Recovered`; the installed system validator is the committed legacy version, not the unreviewed Debian3 candidate. Do not enable backup or treat the validator as a Debian4 recovery contract.
5. **AK default:** managed `~/.config/ak/vault.conf` says `wsl_distro=Debian-Recovered`. No credentials were transferred or retrieved and Windows routing was not changed. Resolve target credential policy explicitly before using it.
6. **Guidance/helper drift:** repository source now reconciles the global Pi guidance template with current machine-owned guidance and points `~/bin/web-search` at the supported agent-skills Node launcher. The retained bootstrap test passes, but no chezmoi apply or Debian4 runtime check has occurred.
7. **Home-content scope:** chezmoi still deploys a historical 2025 transcript text and OpenCode note from committed source. These are not migrated Pi history, but their presence is a source-cleanliness decision for the clean profile.
8. **Validation/transport:** the Bash suite's migration-script lint failure and the two HTTPS clone timeouts remain explicit. No warnings were suppressed to claim a green gate.

These findings mean “bootstrap execution passed” is narrower than “all desired workflows work.” Preserve this baseline before making selected improvements.

## Comparison with preserved systems

Debian-Recovered was inspected read-only while already running. Debian3 had stopped during this work; it was **not restarted**. Its column below is retained 4–5 September session evidence, not fresh runtime verification. No previous system's service, data, configuration or scheduler was changed by this build.

| Area | Debian4, freshly verified | Debian-Recovered, read-only current inspection | Debian3, retained session evidence |
|---|---|---|---|
| Role | Official clean bootstrap candidate | Preserved older environment; owner identifies 3 September state as known good | Prior clean-build attempt plus broad migration |
| OS / systemd | 13.5 / active | 13.5 / active | systemd established during migration |
| Node | 22.19.0 pinned | Installed 24.19.0 and 24.14.0 directories | 22.19.0 at original bootstrap |
| GitHub CLI | Missing | `/usr/bin/gh` present | Missing at last credential-workflow inspection |
| Pi sessions / transcripts | 0 / 0 | 860 / 27 | 860 / 27 verified after migration; later additions not checked |
| McFly | Binary installed; fresh-history initialization warning | Live and recovery DB files present, both 73,728 bytes at inspection | Migrated history/recovery, prior SQLite check passed |
| SSH/GPG/Pi auth | No private keys or Pi auth | SSH/GPG state and Pi auth file present; metadata only inspected | SSH/GPG migration verified; Pi auth not migrated |
| PostgreSQL | Not installed; no data | PostgreSQL 17 main, port 5432, **down** | Logical restores retained; later cutover recorded online on 5432 |
| Routine backup | Software installed, timer disabled, no repository/password | Timer disabled/inactive | Timer enabled after cutover; operational credential/history and restore evidence retained |
| dotfiles source | `1e2915f`, clean | `05710ea`, clean | Previously inspected chezmoi `ad8ec45`; not refreshed here |
| agent-skills source | `6725342`, clean | `766d921`, clean | Not freshly inspected |
| Other repositories | Foundation only | Boat, heatpump, symphony and other checkouts remain | Broad Git worktrees were not migrated |

Debian-Recovered's ak checkout has one dirty entry; its content was not read or copied. Treat it as unresolved source state, not disposable noise. This comparison did not open Restic credentials/repositories, compare database contents again, identify the 3 September recovery artifact, or validate old archive hashes. It supplies no evidence that existing backups are generally bad.

### PostgreSQL and boat relationship

Read `/home/jack/boat-data-platform/README.md` and `docs/operations.md` in Debian-Recovered. They describe PostgreSQL as selected queryable boat history, with raw NMEA 2000 and native MasterBus logs/snapshots as replay sources. The documented operational server is **pi5nvme**, alongside Signal K and Grafana; picanm acquires raw data.

That explains PostgreSQL's project role but does **not** establish why these particular laptop databases exist, whether they contain unique observations, or whether Debian4 needs a server. Do not contact boat hardware, run backfills, discard the databases, or install PostgreSQL on Debian4 from this documentation alone. Inspect the local development/rebuild workflow and provenance next; preserve the existing dumps and clusters meanwhile.

## Evidence locations and final boundary

- Windows install/client logs and committed-source bundles: `C:\Users\jackc\AppData\Local\DotfilesBuilds\Debian4-20260905\`.
- Debian4 root preparation script, original official `wsl.conf`, log and exit marker: `/var/log/debian4-build/`.
- Debian4 bootstrap scripts/logs/exit markers, reviewed chezmoi diff, pseudo-terminal log, package inventory and manifest copy: `/home/jack/.local/state/debian4-build/`.
- Standard bootstrap manifest: `/home/jack/.local/state/dotfiles-bootstrap/installed-manifest.json`.
- Retained test failure and read-only comparison output: this exact-root Pi session. No secret values were printed.

Final registration inventory: Debian4 and Debian-Recovered running; Debian3 and Debian-Backup stopped. No stop command was issued for either preserved source. No build client remained. Runtime state can change naturally after the final client exits. Windows default remains Debian-Backup; no default-distro, Windows AK route, host-wide WSL integration, or Terminal change was performed.

The bounded Debian3 startup and live comparison were subsequently approved and completed below. Next: review the listed bootstrap/source gaps and select the Pi/McFly and credential migration requirements. Do not initialize backups, migrate data, activate additional services, or retire anything merely to complete the comparison.

## Follow-up content/provenance comparison

The owner subsequently authorized the [Debian3 versus Debian-Recovered content comparison](DEBIAN3-RECOVERED-COMPARISON.md). All selected Pi histories and 69 older recovery files match; Bash/McFly differences and additional Debian3 recovery artifacts are expected independent-use/migration state, not evidence of a bad source. Privileged metadata checks then confirmed both Restic repositories remain present (234 snapshot files on Debian-Recovered, 238 on Debian3 at that checkpoint). The historical operation was a copy plus scheduler cutover, not a demonstrated move. No repository-content/integrity test was run during that metadata check.

## Approved live Debian3 comparison — 5 September, 09:12–09:14 UTC

The owner explicitly approved starting Debian3, including the possibility of its enabled services running naturally. Initial registration inspection found it stopped. It was started by an explicit `wsl.exe -d Debian3` command. Checks were read-only: no secret retrieval, manual backup, service change, database write, repository synchronization or migration was performed.

Verified Debian3 state:

- Debian 13.5, default user `jack` (1000:1000), PID 1 systemd.
- Node 22.19.0, npm 10.9.3, Pi 0.85.0, fnm 1.38.1, McFly 0.9.4, chezmoi 2.69.4.
- Backup timer enabled/active; scheduler service inactive with `Result=success` and `ExecMainStatus=0`. This is service-state evidence, not a fresh backup or repository-health validation.
- PostgreSQL 17 main **online at port 5432**. No SQL or database-content comparison was run.
- 860 Pi session files and 27 transcripts.
- McFly live and recovery files both 73,728 bytes, mode 600, owned by jack. Read-only immutable SQLite inspection returned integrity `ok` and 186 command rows in each. Immutable inspection does not establish equality or include any concurrent WAL-only changes; history entries were not printed.
- Retained `roles.sql`, `boatdata_direct.dump` and `boatdata_staging.dump` passed their stored checksums. This verifies retained-file consistency, not a new database restore.
- SSH private-key metadata: jack-owned, mode 600. GPG private-key directory present, jack-owned, mode 700. No private-key contents were read.
- Nonsecret AK routing and backup host both identify Debian3. Runtime Restic password file is root-owned mode 600; recovery confirmation marker remains absent. No password, hash or repository unlock was requested.

### Corrections to the earlier historical comparison

**GitHub CLI is now installed on Debian3:** `/usr/bin/gh`, version 2.46.0. Its usual `~/.config/gh/hosts.yml` is absent; no authentication command was run, so successful Git authentication is not established. `delta`, `nvim`, `uv`, `uvx`, `rg`, `fd` and `hx` remain absent on the inspected PATH.

**A Pi authentication file is now present on Debian3:** 2,035 bytes, mode 600, jack-owned, modified at 08:24:02 BST. Only metadata was inspected. Its existence neither proves usable credentials nor identifies who configured it; the prior statement that Pi auth was not migrated remains a statement about the earlier migration, not current file absence.

Fresh Debian3 repository checks found all four clean:

| Repository | Debian3 current commit | Comparison |
|---|---|---|
| dotfiles / chezmoi | `ad8ec45cd7c82a7b3e37ec43cba17b58b28fb3cc` | Older source lineage than Debian4; no synchronization performed |
| agent-skills | `e6b85bda6e349f0842516276590893b5099a473e` | Verified ancestor, two commits behind Debian4/Windows `6725342` |
| ak | `7c53208f1b48109d8db1b6ed191131d00872c18f` | Same selected commit as Debian4 |
| tools | `42c10893f78ea81d2ad5b57248cbb864b73cc257` | Same selected commit as Debian4 |

### Debian4 cross-check and limits

Debian4 was already running. Its dotfiles `1e2915f` and agent-skills `6725342` checkouts remain clean, `gh` remains absent, the backup timer remains disabled, and PostgreSQL data remains absent.

A **2-byte** jack-owned mode-600 Pi auth file now exists on Debian4, with modification time 09:23:08 BST, after the original absence check and around CLI validation. Its contents were not read. This corrects any interpretation that file absence was permanent; it is not evidence of an authenticated provider or a secret migration. No auth file was copied by this session.

The inventory immediately after the probes found Debian3 running. The final registration recheck after documentation validation found Debian3 stopped again, Debian4 and Debian-Recovered running, and Debian-Backup stopped and still Windows default. No Debian3 termination command was issued; the cause of its stopping was not diagnosed. Enabled services may run naturally while it is active. The fresh comparison confirms a shared core tool baseline plus selected-state differences; it does not make Debian3's databases or backup history requirements of Debian4.

