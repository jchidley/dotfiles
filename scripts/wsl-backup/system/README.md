# Debian4 self-contained system archive

The primary artifact is an ordinary tar/gzip on the **Windows internal drive, outside Debian4's VHDX**. It includes the encrypted `/var/lib/restic/home` repository and excludes plaintext `/home/jack`. External copying is a separate replication step. See the [backup contract](../../../docs/DEBIAN4-BACKUP-CONTRACT.md).

**Production orchestration remains disabled.** The tested archive helper is not yet an automatic WSL/VHDX coordinator. The old root-freeze path must not be retried.

## Offline capture helper

```bash
bash scripts/wsl-backup/system/capture-offline-system READ_ONLY_ROOT EXPECTED_EXT4_UUID /internal-windows-mount/system.tar.gz
```

The caller must establish exclusive offline access first. The helper checks the source's read-only ext4 mount/UUID, the embedded repository's structural presence and that the output uses a different filesystem. It does not stop WSL or authenticate encrypted repository contents.

Included: system files and `/var/lib/restic/home`, retaining snapshot history.

Excluded: `/home/jack`, `/etc/restic/home.password`, runtime contents of `/dev`, `/proc`, `/run`, `/sys`, and temporary/restore contents of `/tmp`, `/var/tmp`, `/var/lib/restic/staging`. Ordinary files under `/mnt` are kept; nested filesystems are not crossed. Failed partial output is retained and completed output is never overwritten.

## Recovery

Extract the archive with `--acls --xattrs --xattrs-include='*' --numeric-owner` into isolated ext4 storage. Run `validate-wsl-system-restore` before restoring home. Privately retrieve the password from Bitwarden, authenticate/check the extracted repository, then restore its manifest-selected snapshot into the recovered root. No original VHDX, external home repository or original GPG agent should be needed. Do not boot before isolation is established.

## GPG credentials

The root-owned `home/restic-home-password` provider invokes GPG as jack. Its stdout is secret and must only be consumed by Restic. The password is encrypted under home and the existing cache lasts at most 20 hours. `credential-unlock` in a visible Debian4 terminal owns normal prompting. The one-time enrollment helper has already been run; do not rerun it over the existing credential.

## Tests

```bash
bash scripts/wsl-backup/test-all fast
sudo bash scripts/wsl-backup/system/test-offline-system.sh
sudo bash scripts/wsl-backup/system/test-restore-validator.sh
```

The offline fixture builds real Restic history, archives the repository with the system, unmounts the source, runs a full data check on the recovered repository and restores an older home version. It also covers metadata, exclusions, corrupt gzip, failed producer and non-overwrite behavior. It does not validate the unfinished automatic production coordinator or real isolated boot.
