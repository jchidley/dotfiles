# Debian4 system backup

The agreed recovery set is an ordinary system tar/gzip plus an encrypted Restic home snapshot. See the [backup contract](../../../docs/DEBIAN4-BACKUP-CONTRACT.md).

**Production capture is disabled.** `Backup-WslSystem.ps1` refuses Preflight/Create until the offline WSL/VHDX coordinator is implemented and tested. Status remains available. Do not use the retired root-freeze capture path.

## Tested archive primitive

```bash
bash scripts/wsl-backup/system/capture-offline-system READ_ONLY_ROOT EXPECTED_EXT4_UUID /outside/source/system.tar.gz
```

This requires an already isolated, read-only ext4 mount. It does not stop WSL, attach a VHDX or prove absence of competing writers. Those are outstanding coordinator responsibilities. Output and partial files must not already exist.

The archive excludes `/home/jack`, `/var/lib/restic/home`, `/etc/restic/home.password` and contents of `/dev`, `/proc`, `/run`, `/sys`, `/tmp`, `/var/tmp`, `/var/lib/restic/staging`. Temporary staging has contained real home restores, so it must not leak into an unencrypted archive. It preserves ordinary root-resident files under `/mnt`. Tar uses numeric ownership, sparse-file support, ACLs and xattrs. Ownership, modes, symlinks, hardlinks, POSIX ACLs, user xattrs and capabilities are fixture-tested. Restore using `--acls --xattrs --xattrs-include='*' --numeric-owner`. VHDX attachment and isolated import/boot remain open.

Failed partial output is retained. Publication does not overwrite existing output. The printed SHA-256 is to be recorded with the exact external home snapshot ID in a validated generation manifest.

## Credential migration

Home backups will use `home/restic-home-password`, a root-owned password-command provider that invokes GPG as jack. The encrypted password lives at `/home/jack/.config/restic/home.password.gpg`. Its stdout is secret and must only be consumed by Restic, never displayed.

`home/prepare-gpg-credential` is an owner-approved root enrollment operation, not a routine installer. It encrypts the existing credential to the existing selected key without printing it, refuses existing output, and preserves the original plaintext file. It neither deploys configuration nor removes the old password.

If the agent is locked, the owner can unlock privately from a Debian4 terminal:

```bash
export GPG_TTY=$(tty)
gpg --decrypt /home/jack/.config/restic/home.password.gpg >/dev/null
```

This prompts for the GPG passphrase, not the Restic password. Do not paste either password into an agent session. Backups retain their existing schedule; GPG has a 20-hour maximum cache, and restart can end the unlock sooner.

## Tests

Run from WSL. Privileged tests use disposable repositories and mounts only:

```bash
bash scripts/wsl-backup/test-all fast
bash scripts/wsl-backup/system/test-combined-home-copy.sh
bash scripts/wsl-backup/system/test-gpg-password-command.sh
sudo bash scripts/wsl-backup/system/test-offline-system.sh
sudo bash scripts/wsl-backup/home/test.sh
```

See [STATUS](../STATUS.md) and [TASKS](../TASKS.md) before production work. Existing encrypted system snapshots and failed generation records must remain preserved until the replacement restore gate passes.
