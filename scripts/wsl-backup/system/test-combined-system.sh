#!/usr/bin/env bash
set -euo pipefail
root=$(mktemp -d /var/tmp/combined-system-test.XXXXXX)
trap 'rm -rf -- "$root"' EXIT
password='SYNTHETIC-SYSTEM-RESTIC-PASSWORD'
printf '%s\n' "$password" >"$root/password"
chmod 600 "$root/password"
mkdir -p "$root/repository" "$root/capture/etc/systemd/system" "$root/capture/usr/local/sbin" \
  "$root/capture/home/jack" "$root/capture/var/lib/restic/home" "$root/restore" \
  "$root/capture/dev" "$root/capture/proc" "$root/capture/run" "$root/capture/sys" "$root/capture/mnt"
printf 'fixture-os\n' >"$root/capture/etc/os-release"
printf '#!/bin/sh\n' >"$root/capture/usr/local/sbin/backup-wsl-home"
printf 'timer\n' >"$root/capture/etc/systemd/system/wsl-home-scheduler.timer"
printf 'HOME-SYNTHETIC-SECRET\n' >"$root/capture/home/jack/private"
printf 'REPOSITORY-SYNTHETIC-SECRET\n' >"$root/capture/var/lib/restic/home/config"
mkdir -p "$root/capture/etc/restic"
printf 'PASSWORD-SYNTHETIC-SECRET\n' >"$root/capture/etc/restic/home.password"
for virtual in dev proc run sys mnt; do printf 'VIRTUAL-SYNTHETIC-SECRET\n' >"$root/capture/$virtual/live"; done
chmod 755 "$root/capture/usr/local/sbin/backup-wsl-home"
ln -s /proc/mounts "$root/capture/etc/mtab"
export RESTIC_PASSWORD_FILE="$root/password"
restic --repo "$root/repository" init --repository-version 2 >/dev/null
repository_id=$(restic --repo "$root/repository" cat config --no-lock | jq -er .id)
cat >"$root/home.conf" <<EOF
RESTIC_PASSWORD_FILE=$root/password
BACKUP_HOST=Debian4
SOURCE=/home/jack
COMBINED_COPY_LOCK_FILE=$root/restic-home.lock
EOF
helper=$(cd -- "$(dirname -- "$0")" && pwd)/capture-combined-system
bash "$helper" "$root/home.conf" "$root/repository" "$repository_id" "$root/capture" preflight >"$root/preflight.log"
bash "$helper" "$root/home.conf" "$root/repository" "$repository_id" "$root/capture" capture >"$root/capture.log"
grep -Eq '^system_repository_verified target=[0-9a-f]{64}$' "$root/preflight.log"
snapshot=$(sed -nE 's/^system_snapshot_created id=([0-9a-f]{64}) filename=system\.tar\.gz$/\1/p' "$root/capture.log")
[[ $snapshot =~ ^[0-9a-f]{64}$ ]]
restic --repo "$root/repository" dump "$snapshot" system.tar.gz | tar -xzf - -C "$root/restore"
[[ -f $root/restore/etc/os-release ]]
[[ ! -e $root/restore/home/jack && ! -e $root/restore/var/lib/restic/home && ! -e $root/restore/etc/restic/home.password ]]
for virtual in dev proc run sys mnt; do [[ ! -e $root/restore/$virtual ]]; done
[[ $(stat -c %a "$root/restore/usr/local/sbin/backup-wsl-home") == 755 ]]
[[ -L $root/restore/etc/mtab && $(readlink "$root/restore/etc/mtab") == /proc/mounts ]]
if find "$root" -path "$root/repository" -prune -o -type f -name 'system.tar.gz' -print | grep -q .; then
  echo 'plaintext system archive was written outside Restic' >&2; exit 1
fi
if grep -R -a -F 'SYNTHETIC-SECRET' "$root/repository"; then echo 'Restic repository exposed synthetic plaintext' >&2; exit 1; fi
if grep -R -F "$password" "$root"/*.log; then echo 'synthetic password leaked to supported output' >&2; exit 1; fi
printf 'Combined system integration passed: streamed Restic encryption, exclusions, metadata, restore\n'
