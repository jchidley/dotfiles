#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'run this disposable mount test as root' >&2; exit 1; }
root=$(mktemp -d /var/tmp/offline-system-test.XXXXXX)
cleanup() {
  if mountpoint -q "$root/source"; then umount "$root/source" || return; fi
  rm -rf -- "$root"
}
trap cleanup EXIT
mkdir "$root/source" "$root/restore"
truncate -s 64M "$root/disk.img"
mkfs.ext4 -q -F "$root/disk.img"
mount -o loop "$root/disk.img" "$root/source"
uuid=$(findmnt --mountpoint "$root/source" -n -o UUID)
mkdir -p "$root/source/etc/restic" "$root/source/home/jack" "$root/source/var/lib/restic/home" \
  "$root/source/mnt" "$root/source/dev" "$root/source/proc" "$root/source/run" "$root/source/sys"
printf 'synthetic-os\n' >"$root/source/etc/os-release"
for path in home/jack/secret etc/restic/home.password; do
  printf 'SYNTHETIC-SECRET\n' >"$root/source/$path"
done
# Create real snapshot history inside the source filesystem. The recovery
# password is kept outside it, simulating independent Bitwarden recovery.
unset RESTIC_PASSWORD RESTIC_PASSWORD_COMMAND RESTIC_PASSWORD_FILE
printf 'synthetic-recovery-password\n' >"$root/password"
export RESTIC_PASSWORD_FILE="$root/password"
restic --repo "$root/source/var/lib/restic/home" --no-cache init >/dev/null
repository_id=$(restic --repo "$root/source/var/lib/restic/home" --no-cache cat config | jq -er .id)
restic --repo "$root/source/var/lib/restic/home" --no-cache backup "$root/source/home/jack" >/dev/null
first_snapshot=$(restic --repo "$root/source/var/lib/restic/home" --no-cache snapshots --json | jq -er '.[0].id')
printf 'new version\n' >"$root/source/home/jack/secret"
restic --repo "$root/source/var/lib/restic/home" --no-cache backup "$root/source/home/jack" >/dev/null
for staging in tmp var/tmp var/lib/restic/staging; do
  mkdir -p "$root/source/$staging/old-restore/home/jack/.ssh"
  printf 'SYNTHETIC-STAGED-SECRET\n' >"$root/source/$staging/old-restore/home/jack/.ssh/id_ed25519"
done
printf 'ordinary root-resident mount-directory file\n' >"$root/source/mnt/ordinary"
chmod 640 "$root/source/etc/os-release"
component=$(cd -- "$(dirname -- "$0")" && pwd)
cc -Wall -Wextra -Werror "$component/test-linux-metadata.c" -o "$root/metadata"
"$root/metadata" seed "$root/source/etc/os-release"
ln "$root/source/etc/os-release" "$root/source/etc/os-release-hardlink"
printf 'synthetic executable\n' >"$root/source/etc/capability-fixture"
setcap cap_net_bind_service=ep "$root/source/etc/capability-fixture"
ln -s /proc/mounts "$root/source/etc/mtab"
helper=$(cd -- "$(dirname -- "$0")" && pwd)/capture-offline-system
if bash "$helper" "$root/source" "$uuid" "$root/system.tar.gz" >/dev/null 2>&1; then
  echo 'writable source accepted' >&2; exit 1
fi
mount -o remount,ro "$root/source"
if bash "$helper" "$root/source" 00000000-0000-0000-0000-000000000000 "$root/system.tar.gz" >/dev/null 2>&1; then
  echo 'wrong filesystem identity accepted' >&2; exit 1
fi
bash "$helper" "$root/source" "$uuid" "$root/system.tar.gz" >"$root/checksum"
sha256sum -c "$root/checksum" >/dev/null
gzip -t "$root/system.tar.gz"
tar --extract --gzip --acls --xattrs --xattrs-include='*' --numeric-owner -f "$root/system.tar.gz" -C "$root/restore"
"$root/metadata" compare "$root/source/etc/os-release" "$root/restore/etc/os-release"
[[ $(stat -c %i "$root/restore/etc/os-release") == $(stat -c %i "$root/restore/etc/os-release-hardlink") ]]
[[ $(getcap "$root/restore/etc/capability-fixture") == *'cap_net_bind_service=ep' ]]
head -c 100 "$root/system.tar.gz" >"$root/truncated.tar.gz"
if gzip -t "$root/truncated.tar.gz" 2>/dev/null; then echo 'truncated gzip accepted' >&2; exit 1; fi
[[ $(stat -c %u:%g:%a "$root/restore/etc/os-release") == 0:0:640 ]]
[[ $(readlink "$root/restore/etc/mtab") == /proc/mounts ]]
cmp "$root/source/mnt/ordinary" "$root/restore/mnt/ordinary"
for staging in tmp var/tmp var/lib/restic/staging; do
  [[ -d $root/restore/$staging && ! -e $root/restore/$staging/old-restore ]]
done
[[ ! -e $root/restore/home/jack && ! -e $root/restore/etc/restic/home.password && -s $root/restore/var/lib/restic/home/config ]]
# Unmount the entire source before opening the recovered repository: recovery
# must depend only on the gzip and independent password, not the original data.
umount "$root/source"
recovered_repo="$root/restore/var/lib/restic/home"
[[ $(restic --repo "$recovered_repo" --no-cache cat config | jq -er .id) == "$repository_id" ]]
[[ $(restic --repo "$recovered_repo" --no-cache snapshots --json | jq length) == 2 ]]
restic --repo "$recovered_repo" --no-cache check --read-data >/dev/null
restic --repo "$recovered_repo" --no-cache restore "$first_snapshot" --target "$root/recovered-home" --verify >/dev/null
[[ $(<"$root/recovered-home$root/source/home/jack/secret") == SYNTHETIC-SECRET ]]
if env -u RESTIC_PASSWORD_FILE RESTIC_PASSWORD_COMMAND=false restic --repo "$recovered_repo" --no-cache cat config >/dev/null 2>&1; then
  echo 'repository opened without recovery credential' >&2; exit 1
fi
mount -o loop,ro "$root/disk.img" "$root/source"
if bash "$helper" "$root/source" "$uuid" "$root/system.tar.gz" >/dev/null 2>&1; then
  echo 'existing archive accepted' >&2; exit 1
fi
printf 'retained-failure' >"$root/other.tar.gz.partial"
if bash "$helper" "$root/source" "$uuid" "$root/other.tar.gz" >/dev/null 2>&1; then
  echo 'existing partial accepted' >&2; exit 1
fi
[[ $(<"$root/other.tar.gz.partial") == retained-failure && ! -e $root/other.tar.gz ]]
# A failing producer must preserve its partial output and never publish success.
mkdir "$root/bin"
printf '#!/bin/sh\nprintf partial-output\nexit 42\n' >"$root/bin/tar"
chmod 755 "$root/bin/tar"
if PATH="$root/bin:$PATH" bash "$helper" "$root/source" "$uuid" "$root/failed.tar.gz" >/dev/null 2>&1; then
  echo 'producer failure accepted' >&2; exit 1
fi
[[ -s $root/failed.tar.gz.partial && ! -e $root/failed.tar.gz ]]
# A system-only archive must now be refused rather than published as complete.
umount "$root/source"
mount -o loop,rw "$root/disk.img" "$root/source"
mv "$root/source/var/lib/restic/home" "$root/source/var/lib/restic/repository-held"
mount -o remount,ro "$root/source"
if bash "$helper" "$root/source" "$uuid" "$root/missing-repository.tar.gz" >/dev/null 2>&1; then
  echo 'system-only source accepted' >&2; exit 1
fi
[[ ! -e $root/missing-repository.tar.gz && ! -e $root/missing-repository.tar.gz.partial ]]
printf 'PASS: self-contained gzip restores embedded Restic history without source; metadata, exclusions, corruption and producer failure\n'
