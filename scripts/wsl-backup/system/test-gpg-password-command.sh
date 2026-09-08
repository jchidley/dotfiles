#!/usr/bin/env bash
# Disposable GPG/Restic contract test; never uses the operator's GPG agent.
set -euo pipefail
[[ $(id -un) == jack ]] || { echo 'run this identity-bound fixture as jack' >&2; exit 1; }
sudo -n true
root=$(mktemp -d)
export GNUPGHOME="$root/gnupg"
mkdir -m 700 "$GNUPGHOME"
cleanup() { gpgconf --kill gpg-agent; rm -rf -- "$root"; }
trap cleanup EXIT
unset RESTIC_PASSWORD RESTIC_PASSWORD_FILE RESTIC_PASSWORD_COMMAND
printf 'synthetic-unlock\n' | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
  --quick-generate-key 'Disposable Restic Test' rsa2048 encr 0 >/dev/null 2>&1
printf 'synthetic-repository-password\n' >"$root/plaintext"
sudo -n chown root:root "$root/plaintext"
sudo -n chmod 600 "$root/plaintext"
gpg --batch --with-colons --list-keys 'Disposable Restic Test' 2>/dev/null |
  awk -F: '$1=="fpr" { print substr($10,length($10)-7); exit }' >"$root/recipient"
home_scripts=$(cd -- "$(dirname -- "$0")/../home" && pwd)
sed -e "s|/etc/restic/home.password|$root/plaintext|g" \
  -e "s|/home/jack/.config/restic/home.password.gpg|$root/password.gpg|g" \
  -e "s|/home/jack/.config/restic|$root|g" \
  -e "s|/home/jack/git/ak/.gpg-key-id|$root/recipient|g" \
  -e "s|/home/jack/.gnupg|$GNUPGHOME|g" \
  "$home_scripts/prepare-gpg-credential" >"$root/enroll"
# The log intentionally belongs to the unprivileged fixture owner.
# shellcheck disable=SC2024
sudo -n bash "$root/enroll" >"$root/enroll.log"
[[ -f $root/plaintext ]]
if sudo -n bash "$root/enroll" >/dev/null 2>&1; then echo 'enrollment overwrote existing credential' >&2; exit 1; fi
if grep -q 'synthetic-repository-password' "$root/enroll.log"; then echo 'credential leaked to enrollment log' >&2; exit 1; fi
# Explicit interactive-unlock equivalent, confined to the synthetic keyring.
printf 'synthetic-unlock\n' | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
  --decrypt "$root/password.gpg" >/dev/null 2>&1
provider=$(cd -- "$(dirname -- "$0")/../home" && pwd)/restic-home-password
# Substitute only storage paths into the real provider. Exercise its actual
# root -> runuser(jack) -> env -i -> GPG sequence with the disposable agent.
sed -e "s|/home/jack/.config/restic/home.password.gpg|$root/password.gpg|g" \
  -e "s|/home/jack/.gnupg|$GNUPGHOME|g" -e "s|HOME=/home/jack|HOME=$root|g" \
  "$provider" >"$root/provider"
export RESTIC_PASSWORD_COMMAND="sudo -n bash $root/provider"
restic --repo "$root/repository" init >/dev/null 2>&1
restic --repo "$root/repository" cat config >/dev/null 2>&1
# A fresh agent has no cached passphrase. Never invalidate the real agent.
gpgconf --kill gpg-agent
if restic --repo "$root/repository" cat config >/dev/null 2>&1; then
  printf 'FAIL: locked GPG unexpectedly unlocked Restic\n' >&2; exit 1
fi
printf 'PASS: real root-to-jack provider uses cached GPG; locked GPG fails without prompting or fallback\n'
