# Debian4 backup and recovery contract

## Agreed design: one internally stored recovery archive

The ordinary system tar/gzip **includes `/var/lib/restic/home`**, the encrypted local Restic repository, and excludes plaintext `/home/jack`. This preserves home snapshot history without duplicating home data. It does not require an external drive to be a complete recovery set.

The archive destination must be on the Windows internal drive, outside the source VHDX. It must not be inside the filesystem being archived, including through an alias. Copying completed archives to a verified external disk is a separate replication step. An archive on the same physical internal drive protects against logical loss, not failure or loss of that drive.

The owner relies on physical security for Windows and external disks; no whole-disk encryption or additional system-archive encryption is imposed. An unencrypted VHDX is not a security boundary.

- `/home/jack` contains user data, GPG keys and encrypted credentials. Automatic Restic snapshots remain in `/var/lib/restic/home`.
- The Restic password is stored at `/home/jack/.config/restic/home.password.gpg`, encrypted to the existing key. Root-run backups invoke GPG as jack through `restic-home-password`.
- Existing GPG cache limits are 72,000 seconds. A locked agent fails unattended operations without pinentry or plaintext fallback; the owner unlocks interactively. This does not change backup frequency.
- Bitwarden provides independent recovery of the Restic password before the home/GPG setup has been restored.
- The archive excludes home, the retired plaintext runtime password, runtime filesystem contents, and contents of `/tmp`, `/var/tmp`, and `/var/lib/restic/staging`. Staged restores and previous backup outputs must not accumulate inside new archives. Existing recovery evidence is preserved, not deleted by capture.
- Ordinary root-resident files under `/mnt` are retained. Mounted filesystems are not crossed.

The plaintext `/etc/restic/home.password` has been removed after GPG and independent recovery checks. No new key, AK service, Windows password process or automated Bitwarden access is needed.

## Capture consistency and implementation boundary

`capture-offline-system` requires an isolated read-only ext4 mount with a pinned filesystem UUID, an embedded repository on that same mount with config/keys/data/index/snapshot directories and at least one snapshot, and an output filesystem different from the source. Structural repository checks are not authentication of its encrypted contents.

It writes a new `.partial` archive, validates paths and presence of the embedded repository, checks source identity again, and publishes without overwriting existing output. The disposable self-contained test creates real snapshot history, archives it, unmounts the source, fully checks the recovered repository, and restores an older home version using only that recovered repository and a separate synthetic password. Metadata, corruption, producer-failure and overwrite checks also pass.

The production coordinator remains disabled. Before enabling it, implement and verify a Windows/WSL procedure to stop Debian4 cleanly, obtain exclusive read-only VHDX access from an approved helper, capture to internal Windows storage, detach and restore the intended distro state. A read-only guest mount alone does not prove there are no other writers. The repository must not be copied as ordinary files while Restic is modifying it. No root freeze or new automatic schedule is enabled by the archive-helper change.

Ordinary `wsl --export` includes both plaintext home and its repository, duplicating data; it does not implement the selected exclusion-aware design.

## Scheduling, manifest and replication

Linux systemd keeps the existing home-backup schedule, operation locks and deletion holds. Failed backups block later scheduler maintenance. Automatic archive orchestration and user-facing failure notification still need implementation; journal errors alone do not establish notification.

A completed-generation manifest must record the internal archive path/checksum, capture time, embedded repository ID, selected home snapshot ID and exclusions. The home snapshot may predate the offline system capture; do not claim a single atomic application snapshot. The self-contained artifact does not depend on an external snapshot ID.

Supported `restic copy` and the pinned USB configuration are retained for optional independent repository replication and historical recovery. They are not prerequisites for creating the internally stored archive. Do not delete historical two-part generations.

## Recovery acceptance

1. Verify the internally stored archive checksum and extract it into a new isolated ext4 root, including its Restic repository.
2. Use `--acls --xattrs --xattrs-include='*' --numeric-owner` so non-user attributes such as Linux capabilities are restored.
3. Retrieve the Restic password privately from Bitwarden, independent of the lost VHDX and backed-up GPG keys.
4. Authenticate and check the extracted repository; verify its manifest-pinned ID and home snapshot.
5. Restore that snapshot into the recovered root and verify actual content and permissions.
6. Keep scheduling, networking and production services disabled before a separately reviewed disposable first boot.
7. Deliberately resume GPG-backed runtime credentials and scheduling after recovery review.

No real self-contained recovery or automatic system archive is claimed until its production tests pass. The earlier real two-part restore and disposable VHDX tests remain useful evidence, but do not replace this gate. See `scripts/wsl-backup/STATUS.md` and `TASKS.md` for evidence and remaining work.
