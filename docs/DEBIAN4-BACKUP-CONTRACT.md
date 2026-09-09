# Debian4 backup and recovery contract

## Agreed design — 9 September 2026

Use two complementary backups:

- **Incremental home backup:** Restic snapshots of `/home/jack`, retaining file history and efficient recovery of accidental changes or deletions.
- **Complete-distro export:** an ordinary full-system tar/gzip produced by `wsl --export`, in addition to the home backup. It includes home, the local Restic repository and other root-filesystem contents without custom exclusions.

The owner selected this combination for efficiency and security considerations. Restic encrypts its repositories as part of how it works; encryption is not an independently requested requirement or the reason for choosing this backup layout. No additional system-archive encryption or new key-management scheme is required. Existing Restic credentials still need to be preserved because Restic requires them to recover its snapshots.

The full export intentionally includes plaintext home and may include credentials, temporary files, staged restores and duplicated home history. This is accepted scope, not an exclusion bug. The owner relies on physical security for storage; the archive must nevertheless be treated as sensitive and must not be published or logged by content. An unencrypted VHDX is not a security boundary either.

This decision supersedes the exclusion-aware archive design of 8 September. `capture-offline-system` and its tests remain preserved prior-design implementation/evidence, not the selected production path. Do not complete its VHDX mount coordinator merely to satisfy that superseded plan.

## Storage and capture

The primary full export belongs on the Windows internal drive, outside Debian4's VHDX, including through aliases. External copying is separate replication. The owner cancelled only the historical pending replication of the retired Debian-Recovered bundle and older archive; optional Debian4 replication remains undecided and is not a prerequisite for the internal export/recovery acceptance work. Storage on the same physical drive protects against logical loss, not failure or loss of that drive.

Capture requires an approved maintenance window and a stopped source distro. Do not automatically terminate Debian4 or wake it for routine polling. The source must remain stopped after capture for archive verification and recovery preparation.

`system/Export-WslFullBackup.ps1` requires an already-stopped distro and explicit reviewed volume/disk unique IDs. It rejects redirected components, non-fixed or non-NTFS/ReFS destinations, non-internal bus types, and disks other than the Windows boot/system disk. It rechecks identity after capture and records it in the manifest. The selected production destination is `C:\WSL-Backups\Debian4\full`, on the reviewed C: NVMe boot/system disk and outside `C:\WSL\Debian4\ext4.vhdx`.

The coordinator runs unfiltered `wsl --export --format tar.gz`, validates gzip and a full archive listing without logging names, and publishes only after recording size and SHA-256. It never restarts the source. Every failure after generation creation leaves the `.partial` directory in place.

The initial native race test proved only that a start is refused after export owns WSL's distro operation lock. A separate disposable probe then proved that WSL will export an already-running distro, so pre/post state checks do not close the initial race. A read-only/share-read source handle was rejected because WSL export itself needs an incompatible VHDX handle.

The accepted candidate instead acquires the stopped source `ext4.vhdx` with exclusive read access, copies it byte-for-byte to a retained internal capture VHDX while hashing both sides, and keeps the source handle open through publication. This prevents Debian4 from obtaining any start handle throughout capture. It registers only the cold copy under a fresh `FullCapture-*` name and produces the ordinary full-system tar/gzip with `wsl --export` from that copy. Registration may change clone-container metadata, so schema 3 records the equal source/cold-copy pre-registration hashes separately from the archive hash. The source, cold clone, archive and failed evidence are never cleaned up automatically.

A post-shutdown native fixture verified exclusive source-start refusal, byte-identical cold copying, clone registration/export, schema-3 manifest and storage identity, archive checksum, import and isolated synthetic boot. The attempted source start failed with `ERROR_SHARING_VIOLATION`. This fixture validates mechanics only, not real Debian4 recovery.

Approved production generation `20260909T170315Z-091d2190` used this path. The source/cold-copy pre-registration SHA-256 values match, and the 6,344,652,800-byte archive independently passed SHA-256, gzip and full listing checks. The production clone `FullCapture-Debian4-091d2190` and its VHDX were retained through real recovery, then removed during explicitly approved closeout cleanup. An external actor repeatedly restarted Debian4 after the exclusive capture handle was released; this did not affect capture, and corrective final shutdown checks passed, but continuous post-capture stopped state is not claimed.

The immutable capture manifest says `restoreTested=false`; recovery acceptance is recorded separately by the completed real recovery result below. No old root-freeze controller is to be re-enabled.

## Home history and scheduling

Existing Linux-owned Restic home backups, systemd scheduling, operation locks and deletion holds remain unchanged. A full export does not replace incremental history, and the latest Restic snapshot can predate the export. Do not claim a single atomic snapshot spanning both operations.

The existing GPG-backed Restic password provider and independent Bitwarden recovery route remain necessary implementation details, not a request for additional encryption. No new key, AK service, Windows password process or automated Bitwarden access is needed.

Do not add Windows scheduling or polling of routine Linux-owned work. Backup cadence, deployment, retention and cleanup are not changed by this design decision.

## Recovery acceptance

1. Verify the full archive's manifest, size and checksum.
2. Import it into a new disposable destination, without replacing an existing distro.
3. Keep the original Debian4 stopped, import under a unique recovery name and location, and observe the restored services and schedules during a normal first boot.
4. Verify actual system/home content and relevant Linux ownership, modes, links and metadata after import and boot.
5. Separately verify that retained Restic history can be authenticated and restored with the independently recoverable password. Direct full-system recovery does not require reconstructing home from Restic first.
6. Preserve original distros and recovery evidence until the real recovery and reconciliation gates pass; retirement requires separate approval.

`system/Test-WslFullExport.ps1` tests a synthetic export/import/boot round trip from an explicit retained seed. It does not enter Debian4. It also checks the reviewed storage identity in schema-3 manifests and the installed WSL start/export exclusion behavior. Its repository landmark is a text fixture, not a real Restic repository. It retains imported fixture distros and generated files. It does not establish real Debian4 recovery, complete metadata preservation or independent password recovery.

## Reviewed and completed real-recovery sequence

The production generation and completed recovery test use these locations:

- accepted export: `C:\WSL-Backups\Debian4\full\20260909T170315Z-091d2190`;
- recovery distro: `Debian4-RecoveryTest-20260909A`;
- import location: `C:\WSL-RecoveryTests\Debian4-RecoveryTest-20260909A`.

The completed first approval recorded the nonsecret source baseline, shut down WSL and ran disposable concurrency candidates. It did not run production export because the originally reviewed direct-export operation was rejected. A second explicit approval authorized the following cold-copy production command, independent schema-3/archive verification and final shutdown:

```powershell
& C:/Users/jackc/git/dotfiles/scripts/wsl-backup/system/Export-WslFullBackup.ps1 `
  -Distro Debian4 `
  -OutputDirectory C:/WSL-Backups/Debian4/full `
  -ExpectedVolumeUniqueId '\\?\Volume{e2af63ea-0368-46ab-a7df-a69c91353abb}\' `
  -ExpectedDiskUniqueId 'eui.000000000000000100A075244BA2F6C2'
```

The shutdown stops Debian4 and any other WSL VM activity. The command creates a sensitive retained cold VHDX under `C:\WSL-Backups\Debian4\full\capture-sources`, registers it under a fresh generated `FullCapture-Debian4-*` name, and creates one schema-3 tar/gzip generation. Current source VHDX size is 16,502,489,088 bytes; the historical archive suggests roughly another 21.4 GB, with more than 500 GB free on C:. The clone registration and all files remain preserved. Any failure blocks publication but retains partial evidence. A final shutdown and stopped-state check follow the command.

This replacement operation completed with the generation and evidence recorded above. At that checkpoint it did not authorize a real recovery import/boot, cleanup, source restart or retirement. The later exact reviewed recovery operation completed as recorded below; cleanup, source restart and retirement remain separate decisions.

Before capture, record path-only/hash/stat baselines for `/etc/os-release`, `/etc/wsl.conf`, `/etc/mtab`, `/home/jack/.ssh/id_ed25519`, `/home/jack/.pi/agent/sessions`, `/home/jack/.local/share/mcfly/history.db`, `/home/jack/git/dotfiles/.git`, `/var/lib/restic/home/config`, and the scheduler units. Include source UID/GID/mode, the `mtab` link target, one same-device hardlink pair, and available ACL, user-xattr and capability examples; do not print secret contents.

Archive size/SHA-256, every schema-3 manifest field and a drained `tar -tzf` listing have passed independently. For recovery, import the unchanged archive under the unique reviewed name and location while Debian4 remains stopped, then boot that recovery distro normally. No firewall change, offline VHD modification or elevation is required solely for this test.

Verify the actual baselines above, Debian release, configured user UID/GID, file counts, hashes, SSH mode, McFly SQLite integrity, symlink/hardlink identity, retained ACL/xattr/capability metadata, and the observed state of services and schedules. Verify the embedded Restic repository ID is `fad9e4c059250bf3d0d22ab90018ba599d09b57deaed944c4e0b1277c7c81dac`; with private owner entry of the independently recovered password, run repository authentication, `check --read-data`, and a verified restore of a selected older snapshot to a new path inside the recovery distro. Do not automate Bitwarden or print the password.

Stop the recovery distro after verification. At the recovery checkpoint, keep Debian4 stopped and retain the archive, manifest, imported distro, failed generations, fixture distros, and all prior backups/evidence. The later explicitly approved closeout removed disposable fixtures, the superseded generation, and the cold clone while retaining the accepted archive, imported recovery distro/restored tree, and required evidence.

This sequence completed on 9 September. Normal boot verified the real system/home landmarks and scheduler state. Private entry of the independently recovered password authenticated the expected 106-snapshot repository; `check --read-data` passed all 296 packs, and an older 8.306 GiB snapshot restored with 85,657 files verified. The imported distro, restored tree and evidence remain retained and stopped. Exact comparison of ACL/user-xattr/capability examples was not completed because no corresponding retained source examples were available; this limitation does not negate the verified archive, content, ownership/mode, link, database and Restic recovery results.

This document records the owner's selected design and completed production capture/recovery assurance. Dated evidence belongs in `scripts/wsl-backup/STATUS.md`; outstanding work belongs in `TASKS.md`.
