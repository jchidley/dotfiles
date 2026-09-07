# WSL backup and recovery tasks

Only current incomplete work belongs here. Dated implementation and production evidence lives in [`STATUS.md`](STATUS.md); the [Debian4 plan](../../docs/DEBIAN4-PLAN.md) owns sequencing and approval boundaries.

## Current priority

**Completed Pi import — 6 September 2026:** `debian4-import-execution-20260906T112532Z/REPORT.md` under the [inspection evidence root](../../docs/DEBIAN-BACKUP-INSPECTION.md) records 905 native files and 2,826 archive payload files published without overwrites; separate verification passed with zero failures. The session-isolated launcher resolved two preserved SIGHUP failures. The 24-file execution seal and controller review are complete. Do not rerun the importer.

Retain `/home/jack/.local/state/pi-recovery-import/20260906T112532Z/`, fixtures, the imported recovery archive and all originals/source distros. Cleanup or retirement needs separate approval. The unresolved-gap report still protects two partial-only sessions, 2,943 unconfirmed transcript records, 14 unmerged message candidates, stream fragments and conflicts; none was silently promoted or merged. Further analysis must target a concrete gap, and broad specialist recovery needs a materially revised reviewed strategy.

1. Optional credential follow-up: exact AK value equality with the passphrase-locked Debian-Recovered source remains unverified; Debian4's 14 expected services resolve through the approved route. The owner successfully unlocked the imported SSH key privately with `ssh-keygen -y`; no replacement is needed. Remote SSH authentication remains untested.
2. Local Debian4 home backup is complete: protected runtime credential, independently tested recovery password, pinned repository, verified restore, enabled Linux timer, normal cadence and owner-driven restart observation. See STATUS for evidence. Keep the separate whole-distro exporter review below open.
3. Keep Debian-Recovered, Debian-Backup and forensic evidence until the Debian4 restore gate passes; retirement requires separate final inventory and approval.

Completed on 7 September: boat-data-platform's 19 commits are pushed at `d18e28d`; the recovered heatpump lineage and Windows guidance were reconciled and pushed at `8bab653`; the AK patch was rebased and pushed at `95ef0a7`; and the remaining McFly/web-search/Pi-guidance bootstrap changes were validated, pushed and deployed at dotfiles `fe8736a`.

## Separate whole-distro backup work awaiting review

- Preserve Linux/systemd ownership of routine backup scheduling and whole-distro coordination.
- Resolve the remaining [Debian4 backup contract's candidate findings](../../docs/DEBIAN4-BACKUP-CONTRACT.md): exporter/validator landmarks, unchecked destructive cleanup, unproven first-boot isolation, journal/mutex identity mismatch, and insufficient controller behavioral tests. Home landmarks and the recovery-password tester were corrected separately.
- Remove Debian3-specific recovery landmarks from the unfinished exporter/validator candidate; PostgreSQL remains undecided.
- Demonstrate isolated disposable-import behavior before deployment. The exact-source canonical fast lane passed and is recorded in STATUS; fixture success does not establish restore safety.
- Finalize the contract's proposed Debian4 contents after capability/data selection.
- Preserve the enrolled Debian4 home repository and recovery credential. Any additional repository requires its own reviewed provisioning; never initialize over surviving Restic history.

## Deferred

- PostgreSQL installation or activation on Debian4 pending a workflow decision.
- Optional additional external replication and whole-distro archive storage/encryption choices; the local home repository and its recovery credential are already enrolled.

Windows default distro was changed to Debian4 and independently verified on 7 September 2026. AK routing already targets Debian4. Neither cutover remains pending.

Rust/mold setup completed with owner approval: Debian4 has Rust/Cargo 1.98.1, mold 2.37.1, and build-essential. A disposable offline Cargo build ran successfully and its ELF comment independently identified mold. Native x86-64 Linux Cargo defaults select mold. Debian4 committed the Rust/bootstrap work at `c91bd6f`. Subsequent checkout integration preserved its newer Rust tests and combined them with Windows AK/history tests, fixed the AK-disabled bare-return bug, and synchronized the six selected bootstrap/instruction source files. The combined bootstrap Bash suite and native PowerShell preview/lint checks passed; no bootstrap rerun or blanket chezmoi apply occurred. These additional source changes are locally committed at `300d46a` (bootstrap) and `fc8b1e3` (guidance); Windows was fast-forwarded to that history with its pending work preserved. The broader backup candidate is not accepted for execution; earlier partial fast-gate evidence is retained under `~/.local/state/rust-mold-setup-20260907/fast-gate.log`.
- Removal of Debian-Recovered or Debian-Backup until extraction is complete and Debian4 recovery is independently demonstrated.
- Long-job consent-bridge deployment and prune/full-data-check scheduling.

Debian2 and Debian3 are retired and are not execution targets. Historical task fixtures that name old systems remain implementation/test evidence until reviewed separately; do not remove them solely because the distros are gone.
