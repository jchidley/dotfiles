# WSL backup and recovery tasks

Only current incomplete work belongs here. Dated implementation and production evidence lives in [`STATUS.md`](STATUS.md); the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequencing and approval boundaries.

## Current priority

**Owner-ordered closeout — 9 September 2026:** first review and disposition the final recovered material from the verified Debian4 workspace `/home/jack/recovery/debian-final-recovery-20260909`; then complete the Windows-owned Debian4 full-export and real separate-distro recovery assurance. Only after both are resolved should Debian-Backup retirement/cleanup and final documentation reconciliation proceed. The previously pending replication of the retired Debian-Recovered bundle and its older Restic archive to `bs29063p00036` is cancelled; optional Debian4 replication is explicitly deferred, not cancelled or required for current acceptance.

Dirty-state disposition is complete. Terminal/retirement commit `4a55d6a` and final-recovery record commit `2599295` are published. The untracked Helix installer was deleted after its exact hash was checked; Helix 25.7.1-1 remains installed at `/usr/bin/hx`. The only retained Windows changes are the full-export candidate and its four mixed contract/plan/status/task records. Production cold capture and a fresh repeat of the disposable schema-3 fixture have passed, but all six paths remain unstaged pending source/documentation integration review; the complete fast gate predates the latest candidate.

**Completed Pi import — 6 September 2026:** `debian4-import-execution-20260906T112532Z/REPORT.md` under the [inspection evidence root](../../docs/DEBIAN-BACKUP-INSPECTION.md) records 905 native files and 2,826 archive payload files published without overwrites; separate verification passed with zero failures. The session-isolated launcher resolved two preserved SIGHUP failures. The 24-file execution seal and controller review are complete. Do not rerun the importer.

Retain `/home/jack/.local/state/pi-recovery-import/20260906T112532Z/`, fixtures, the imported recovery archive, Debian-Backup, the immutable forensic image, and historical evidence. Debian-Recovered was separately approved and permanently retired on 9 September 2026. The unresolved-gap report still protects two partial-only sessions, 2,943 unconfirmed transcript records, 14 unmerged message candidates, stream fragments and conflicts; none was silently promoted or merged. Further analysis must target a concrete gap, and broad specialist recovery needs a materially revised reviewed strategy.

1. Credential migration is closed: Debian4's 14 expected services resolve through the approved route, and the former Debian-Recovered source was retired by owner decision. The owner successfully unlocked the imported SSH key privately with `ssh-keygen -y`; no replacement is needed. Remote SSH authentication remains untested.
2. Local Debian4 home backup is complete: protected runtime credential, independently tested recovery password, pinned repository, verified restore, enabled Linux timer, normal cadence and owner-driven restart observation. See STATUS for evidence. Keep the separate whole-distro exporter review below open.
3. Keep Debian-Backup, the immutable forensic image, and historical evidence until their remaining gates pass; retirement requires separate final inventory and approval.

Completed on 7 September: boat-data-platform's 19 commits are pushed at `d18e28d`; the recovered heatpump lineage and Windows guidance were reconciled and pushed at `8bab653`; the AK patch was rebased and pushed at `95ef0a7`; and the remaining McFly/web-search/Pi-guidance bootstrap changes were validated, pushed and deployed at dotfiles `fe8736a`.

## Current implementation gates — 8 September 2026

1. GPG-backed credentials are deployed; fresh backup `3e313f1f`, status, source comparisons and ciphertext recovery passed without resetting the agent. Do not repeat enrollment or deployment.
2. Independent Bitwarden recovery and plaintext removal are complete. Natural scheduling passed at 08:03–08:04 after correcting the obsolete unit condition; cached GPG access and snapshot status are healthy. Locked-agent behavior is fixture-tested; user-facing failure notification remains a separate visibility gap. Do not clear the real cache for testing. Preserve deletion holds and timer policy.
3. **Completed 9 September:** approved schema-3 production generation `20260909T170315Z-091d2190` used the accepted exclusive cold-copy design. Source/cold-copy pre-registration SHA-256 matched; the 6,344,652,800-byte archive independently passed SHA-256, gzip and full listing checks; internal storage identity and retained clone `FullCapture-Debian4-091d2190` passed. STATUS records evidence and post-capture external source restarts. Preserve the archive, clone, registration, prior schema-1 archive and all failed fixtures.
4. **Completed 9 September:** real import/normal boot under `Debian4-RecoveryTest-20260909A` verified Debian/systemd, UID/GID, actual home/system landmarks, SSH mode, Pi counts, clean dotfiles state, McFly integrity and scheduler behavior. Private entry of the independently recovered password authenticated the expected 106-snapshot Restic repository; `check --read-data` passed all 296 packs and an older 8.306 GiB snapshot restored with 85,657 files verified. The recovery distro and restored tree are retained and stopped. STATUS records hashes and the narrow ACL/xattr/capability comparison limitation. Do not repeat production capture or this recovery test.
5. The 9 September complete fast gate predates the focused safety changes. Final focused PSScriptAnalyzer, parsing and diff checks and the accepted cold-clone fixtures passed. Production capture and real-recovery evidence are complete; source/documentation integration remains unpublished. Replication, cleanup, source restart and retirement remain separate operations.

## Preserved prior generation — not the current design

Production generation `20260907T225805Z` now exists on `bs29063p00036`, linking exact home and system snapshots in the encrypted external Restic repository. Capture, streamed archive validation, promotion, thaw, timer restoration, mount removal, journal removal, and post-run health checks passed. Two earlier failed attempts and one unpromoted Restic snapshot remain preserved; nothing was deleted or pruned.

Remaining gates:

- Independently restore both manifest-pinned snapshots into a new offline/network-isolated ext4 target before accepting the combined backup end-to-end.
- Recreate empty runtime mount points (`dev`, `proc`, `run`, `sys`, and `mnt`) before isolated import validation.
- Preserve failed run evidence, existing repositories, recovery evidence, and both recovery distros. Cleanup, first boot, deployment, and source retirement remain separate approvals.

Fixture and capture success do not prove isolated import or safe first boot.

## Deferred

- PostgreSQL installation or activation on Debian4 pending a workflow decision.
- Optional additional external replication. The complete-distro archive needs no additional encryption; Restic encryption is incidental to its implementation. The local home repository and recovery credential are already enrolled.

Windows default distro was changed to Debian4 and independently verified on 7 September 2026. AK routing already targets Debian4. Neither cutover remains pending.

Rust/mold setup completed with owner approval: Debian4 has Rust/Cargo 1.98.1, mold 2.37.1, and build-essential. A disposable offline Cargo build ran successfully and its ELF comment independently identified mold. Native x86-64 Linux Cargo defaults select mold. Debian4 committed the Rust/bootstrap work at `c91bd6f`. Subsequent checkout integration preserved its newer Rust tests and combined them with Windows AK/history tests, fixed the AK-disabled bare-return bug, and synchronized the six selected bootstrap/instruction source files. The combined bootstrap Bash suite and native PowerShell preview/lint checks passed; no bootstrap rerun or blanket chezmoi apply occurred. These additional source changes are locally committed at `300d46a` (bootstrap) and `fc8b1e3` (guidance); Windows was fast-forwarded to that history with its pending work preserved. The broader backup candidate is not accepted for execution; earlier partial fast-gate evidence is retained under `~/.local/state/rust-mold-setup-20260907/fast-gate.log`.
- Removal of Debian-Backup until extraction is complete and Debian4 recovery is independently demonstrated. Debian-Recovered was retired on 9 September 2026.
- Long-job consent-bridge deployment and prune/full-data-check scheduling.

Debian2 and Debian3 are retired and are not execution targets. Historical task fixtures that name old systems remain implementation/test evidence until reviewed separately; do not remove them solely because the distros are gone.
