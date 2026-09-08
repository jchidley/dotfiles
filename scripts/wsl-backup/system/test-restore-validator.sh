#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'run this fixture as root' >&2; exit 1; }
root=$(mktemp -d /var/tmp/system-validator-test.XXXXXX)
trap 'rm -rf -- "$root"' EXIT
mkdir -p "$root/etc/systemd/system" "$root/usr/local/sbin" "$root/var/lib/restic/home"
printf 'synthetic encrypted config\n' >"$root/var/lib/restic/home/config"
for file in etc/os-release usr/local/sbin/backup-wsl-home usr/local/sbin/wsl-home-scheduler \
  etc/systemd/system/wsl-home-scheduler.service etc/systemd/system/wsl-home-scheduler.timer; do
  touch "$root/$file"
done
chmod 755 "$root/usr/local/sbin/backup-wsl-home"
helper=$(cd -- "$(dirname -- "$0")" && pwd)/validate-wsl-system-restore
for target in /proc/mounts ../proc/self/mounts; do
  ln -sfn "$target" "$root/etc/mtab"
  bash "$helper" "$root" >/dev/null
done
mv "$root/var/lib/restic/home/config" "$root/repository-config"
if bash "$helper" "$root" >/dev/null 2>&1; then echo 'missing repository accepted' >&2; exit 1; fi
mv "$root/repository-config" "$root/var/lib/restic/home/config"
ln -sfn /etc/passwd "$root/etc/mtab"
if bash "$helper" "$root" >/dev/null 2>&1; then echo 'invalid mtab target accepted' >&2; exit 1; fi
printf 'PASS: restored Debian mtab targets accepted; unrelated target rejected\n'
