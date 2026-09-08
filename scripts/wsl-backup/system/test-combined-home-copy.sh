#!/usr/bin/env bash
set -euo pipefail
root=$(mktemp -d /var/tmp/combined-home-copy-test.XXXXXX)
trap 'rm -rf -- "$root"' EXIT
password='SYNTHETIC-RESTIC-PASSWORD-NOT-A-REAL-CREDENTIAL'
printf '%s\n' "$password" >"$root/password"
chmod 600 "$root/password"
mkdir -p "$root/source/data" "$root/cache" "$root/local" "$root/external"
printf 'fixture\n' >"$root/source/data/file"
export RESTIC_PASSWORD_FILE="$root/password" RESTIC_CACHE_DIR="$root/cache"
restic --repo "$root/local" init --repository-version 2 >/dev/null
source_id=$(restic --repo "$root/local" cat config --no-lock | jq -er .id)
restic --repo "$root/local" backup --host Debian4 "$root/source" >/dev/null
restic --repo "$root/external" init --repository-version 2 --copy-chunker-params \
  --from-repo "$root/local" --from-password-file "$root/password" >/dev/null
target_id=$(restic --repo "$root/external" cat config --no-lock | jq -er .id)
cat >"$root/home.conf" <<EOF
RESTIC_REPOSITORY=$root/local
RESTIC_PASSWORD_COMMAND='cat $root/password'
RESTIC_CACHE_DIR=$root/cache
BACKUP_HOST=Debian4
SOURCE=$root/source
COMBINED_COPY_LOCK_FILE=$root/restic-home.lock
EOF
helper=$(cd -- "$(dirname -- "$0")" && pwd)/copy-combined-home-snapshot
bash "$helper" preflight "$root/home.conf" "$root/external" "$source_id" "$target_id" >"$root/preflight.log"
bash "$helper" copy "$root/home.conf" "$root/external" "$source_id" "$target_id" >"$root/copy.log"
grep -Eq '^repositories_verified source=[0-9a-f]{64} target=[0-9a-f]{64}$' "$root/preflight.log"
grep -Eq '^snapshot_copied source_snapshot=[0-9a-f]{64} target_snapshot=[0-9a-f]{64}$' "$root/copy.log"
target_snapshot=$(sed -nE 's/^snapshot_copied source_snapshot=[0-9a-f]{64} target_snapshot=([0-9a-f]{64})$/\1/p' "$root/copy.log")
restic --repo "$root/external" restore "$target_snapshot" --target "$root/restored" >/dev/null
cmp "$root/source/data/file" "$root/restored$root/source/data/file"
[[ $(restic --repo "$root/external" snapshots --json | jq 'length') -eq 1 ]]
if bash "$helper" preflight "$root/home.conf" "$root/external" "$source_id" "$(printf '0%.0s' {1..64})" >"$root/wrong.log" 2>&1; then
  echo 'wrong repository identity was accepted' >&2; exit 1
fi
grep -q 'target repository identity mismatch' "$root/wrong.log"
if grep -R -F "$password" "$root"/*.log; then echo 'synthetic password leaked to supported output' >&2; exit 1; fi
if grep -Eq '\b(forget|prune)\b' "$helper"; then echo 'copy helper contains a deletion operation' >&2; exit 1; fi
printf 'Combined home-copy integration passed: supported Restic copy, identity refusal, no credential output\n'
