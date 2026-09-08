# Debian4 backup and recovery contract

## Agreed design

The owner relies on physical security for Windows and external disks. This workflow does not add whole-disk encryption or encrypt the system archive. An unencrypted VHDX is not a security boundary.

- `/home/jack` contains user data, GPG keys and encrypted credentials. Restic encrypts its snapshots automatically.
- The Restic repository password is to be stored at `/home/jack/.config/restic/home.password.gpg`, encrypted to the existing GPG key. Root-run backups use the root-owned `restic-home-password` provider to invoke GPG as jack.
- The existing agent configuration has `default-cache-ttl 72000` and `max-cache-ttl 72000`. This governs passphrase caching, not backup frequency. Agent restart can lock it sooner. A locked agent fails unattended operations without pinentry or plaintext fallback; the owner unlocks interactively.
- Bitwarden remains the independent Restic recovery credential. Recovery must not depend on GPG keys that are themselves inside the backup.
- The remaining system is an ordinary metadata-preserving tar/gzip, excluding home, the local Restic repository and the old plaintext runtime password. Runtime filesystem contents and contents of `/tmp`, `/var/tmp`, and `/var/lib/restic/staging` are excluded. Real restore testing found temporary copies of home SSH keys under `/var/tmp`; excluding `/home/jack` alone is insufficient. Preserve the existing encrypted snapshots/recovery evidence rather than deleting those copies. Ordinary root-resident files under `/mnt` must not be discarded merely because of their pathname.

No new key, AK service, Windows password process or automatic Bitwarden access is needed. The old `/etc/restic/home.password` is removed only after the new provider and independent recovery are verified. Ordinary deletion is not a claim of erasing historical VHDX blocks or prior copies.

## Current implementation boundary

The previous root-freeze/Restic-system controller is disabled for both Preflight and Create. Do not retry it. Its snapshots and failure evidence remain preserved.

`capture-offline-system` is a tested archive primitive, not a production WSL coordinator. It requires an isolated read-only ext4 mount with a caller-pinned filesystem UUID. It writes a new `.partial` archive, validates it, checks the mount again, then publishes without replacing existing output. The disposable restore test verifies ownership, modes, symlinks, hardlinks, POSIX ACLs, user xattrs and Linux capabilities. Restore with `--acls --xattrs --xattrs-include='*' --numeric-owner`; the wildcard is required to recover non-user attributes such as capabilities.

Before production capture, a reviewed Windows/WSL procedure must stop Debian4 cleanly, attach its VHDX exclusively for read-only access from an approved helper environment, verify identity and absence of competing writers, capture, detach and restore the intended final distro state. Read-only mount options alone do not prove exclusive offline access. Ordinary `wsl --export` has no exclusions; a plaintext whole-distro intermediate containing home is not an acceptable substitute.

## Home integration

Linux systemd retains the existing backup frequency, operation locks and persistent deletion holds. Credential changes do not authorise retention, prune or changes to those policies. Failed backups block later scheduler maintenance and must be visible to the operator. A user-facing missed-backup notification is not established by a journal error alone.

Supported `restic copy` is retained. Both source and target repository identities are checked. Copy returns the local source ID and the exact external snapshot ID, which can differ. A recovery manifest must identify the external ID, system archive checksum, capture times, exclusions and repository identity. Separate home/system captures are not claimed to be one atomic instant.

Device identity pins remain in `scripts/wsl-backup/system/combined-backup.json`; drive letters are transport only.

## Recovery acceptance

1. Verify the archive checksum and pinned external repository ID.
2. Extract the system into a new isolated ext4 target with ownership, ACL and xattr restoration.
3. Retrieve the Restic password from Bitwarden privately, without relying on the source VHDX or GPG keys.
4. Restore the manifest-pinned external home snapshot into the recovered root.
5. Verify content, ownership, permissions and key recovery landmarks.
6. Keep scheduling, networking and production services disabled before a separately approved disposable first boot.
7. Re-enrol runtime credentials deliberately, then verify scheduling only after recovery review.

No real combined recovery is accepted until this test passes. Capture, archive listing, checksums and fixture tests alone are insufficient. Preserve existing repositories, failed runs and recovery distros; cleanup or retirement requires separate approval.

See `scripts/wsl-backup/STATUS.md` for dated evidence and `scripts/wsl-backup/TASKS.md` for remaining gates.
