#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run this test as root" >&2; exit 1; }
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(mktemp -d /var/tmp/restic-home-test.XXXXXX)
trap 'rm -rf "$root"' EXIT
source_dir=$root/source
mkdir -p \
  "$source_dir/.pi/agent/sessions" \
  "$source_dir/.local/share/chezmoi" \
  "$source_dir/.local/share/mcfly" \
  "$source_dir/.ssh" \
  "$source_dir/boat-data-platform/.git"
printf 'session\n' > "$source_dir/.pi/agent/sessions/one.jsonl"
printf 'private-test-key\n' > "$source_dir/.ssh/id_ed25519"
chmod 600 "$source_dir/.ssh/id_ed25519"
printf 'payload\n' > "$source_dir/document.txt"
sqlite3 "$source_dir/.local/share/mcfly/history.db" \
  'CREATE TABLE commands (id INTEGER PRIMARY KEY, cmd TEXT); INSERT INTO commands(cmd) VALUES ("test");'

password=$root/password
head -c 48 /dev/urandom | base64 > "$password"
chmod 600 "$password"
touch "$root/bitwarden-confirmed"
chmod 600 "$root/bitwarden-confirmed"

config=$root/home.conf
cat > "$config" <<EOF
SOURCE=$source_dir
RESTIC_REPOSITORY=$root/repository
RESTIC_PASSWORD_FILE=$password
RECOVERY_CONFIRMATION_FILE=$root/bitwarden-confirmed
LOG_DIR=$root/logs
LOG_RETENTION_DAYS=30
STAGING_DIR=$root/staging
RESTIC_CACHE_DIR=$root/cache
BACKUP_HOST=restic-home-test
EXPECTED_UID=0
EXPECTED_GID=0
MIN_BYTES=1
MIN_FILES=3
MIN_SESSIONS=1
MAX_SNAPSHOT_AGE_SECONDS=1800
MCFLY_DATABASE=.local/share/mcfly/history.db
MCFLY_RECOVERY_COPY=.local/share/mcfly/history.db.restic-backup
EOF
# Preserve the variable reference for expansion when the generated config is sourced.
# shellcheck disable=SC2016
printf '%s\n' 'REQUIRED_LANDMARKS=(.pi/agent/sessions .local/share/chezmoi .ssh/id_ed25519 boat-data-platform/.git "$MCFLY_DATABASE")' >> "$config"
chmod 600 "$config"

run() {
  RESTIC_HOME_CONFIG=$config "$SCRIPT_DIR/backup-wsl-home" "$@"
}

run init
touch "$root/logs/expired.log"
touch -d '40 days ago' "$root/logs/expired.log"
run backup
[[ ! -e "$root/logs/expired.log" ]]
run backup
run retention
run check
run check-read-data
run status
[[ $(RESTIC_REPOSITORY=$root/repository RESTIC_PASSWORD_FILE=$password restic snapshots --json | jq 'length') -eq 2 ]]

mv "$source_dir/.ssh/id_ed25519" "$source_dir/.ssh/id_ed25519.missing"
if run validate "$source_dir" >/dev/null 2>&1; then
  echo "source guard accepted a missing landmark" >&2
  exit 1
fi
mv "$source_dir/.ssh/id_ed25519.missing" "$source_dir/.ssh/id_ed25519"

restore=$root/restore
run restore latest "$restore"
cmp "$source_dir/document.txt" "$restore${source_dir}/document.txt"
[[ $(sqlite3 "$restore${source_dir}/.local/share/mcfly/history.db.restic-backup" 'PRAGMA integrity_check;') == ok ]]

printf 'Restic home tests passed.\n'
