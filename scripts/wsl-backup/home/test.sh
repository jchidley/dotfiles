#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run this test as root" >&2; exit 1; }
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(mktemp -d /var/tmp/restic-home-test.XXXXXX)
trap 'rm -rf "$root"' EXIT
source_dir=$root/source
mkdir -p \
  "$source_dir/.pi/agent/sessions" \
  "$source_dir/.local/share/chezmoi/.git" \
  "$source_dir/.local/share/mcfly" \
  "$source_dir/.ssh" \
  "$source_dir/git/dotfiles/.git"
for number in {1..10}; do
  printf 'session %s\n' "$number" > "$source_dir/.pi/agent/sessions/$number.jsonl"
done
for number in {1..20}; do
  head -c 1024 /dev/urandom > "$source_dir/document-$number.bin"
done
printf 'private-test-key\n' > "$source_dir/.ssh/id_ed25519"
chmod 600 "$source_dir/.ssh/id_ed25519"
sqlite3 "$source_dir/.local/share/mcfly/history.db" \
  'CREATE TABLE commands (id INTEGER PRIMARY KEY, cmd TEXT); INSERT INTO commands(cmd) VALUES ("test");'

password=$root/password
head -c 48 /dev/urandom | base64 > "$password"
chmod 600 "$password"
touch "$root/bitwarden-confirmed"
chmod 600 "$root/bitwarden-confirmed"
RESTIC_REPOSITORY=$root/repository RESTIC_PASSWORD_FILE=$password restic init >/dev/null
repository_id=$(RESTIC_REPOSITORY=$root/repository RESTIC_PASSWORD_FILE=$password \
  restic cat config | jq -er .id)

config=$root/home.conf
cat > "$config" <<EOF
SOURCE=$source_dir
LOCK_FILE=$root/operation.lock
RESTIC_REPOSITORY=$root/repository
EXPECTED_REPOSITORY_ID=$repository_id
RESTIC_PASSWORD_FILE=$password
RECOVERY_CONFIRMATION_FILE=$root/bitwarden-confirmed
LOG_DIR=$root/logs
LOG_RETENTION_DAYS=30
STAGING_DIR=$root/staging
RESTIC_CACHE_DIR=$root/cache
SOURCE_BASELINE_FILE=$root/source-baseline
INCIDENT_HOLD_FILE=$root/retention.hold
BACKUP_HOST=restic-home-test
EXPECTED_UID=0
EXPECTED_GID=0
MIN_BYTES=1
MIN_FILES=3
MIN_SESSIONS=1
MIN_BASELINE_BYTES_PERCENT=80
MIN_BASELINE_FILES_PERCENT=80
MIN_BASELINE_SESSIONS_PERCENT=80
MAX_SNAPSHOT_AGE_SECONDS=1800
MCFLY_DATABASE=.local/share/mcfly/history.db
MCFLY_RECOVERY_COPY=.local/share/mcfly/history.db.restic-backup
EOF
# Preserve the variable reference for expansion when the generated config is sourced.
# shellcheck disable=SC2016
printf '%s\n' 'REQUIRED_LANDMARKS=(.pi/agent/sessions .local/share/chezmoi .ssh/id_ed25519 git/dotfiles/.git "$MCFLY_DATABASE")' >> "$config"
chmod 600 "$config"

run() {
  RESTIC_HOME_CONFIG=$config "$SCRIPT_DIR/backup-wsl-home" "$@"
}
expect_failure() {
  if run "$@" >/dev/null 2>&1; then
    echo "expected failure: $*" >&2
    exit 1
  fi
}

# Reproduce the preserved one-off backup: same source/host, extra capture path,
# old timestamp. Status must choose the newer home-only group after backup.
mkdir "$root/capture"
printf 'one-off capture\n' > "$root/capture/evidence"
RESTIC_REPOSITORY=$root/repository RESTIC_PASSWORD_FILE=$password restic backup \
  "$source_dir" "$root/capture" --host restic-home-test --time '2020-01-01 00:00:00' >/dev/null
run enroll-baseline
expect_failure enroll-baseline
run init
sed -i "s|^RESTIC_REPOSITORY=.*|RESTIC_REPOSITORY=$root/must-not-create|" "$config"
expect_failure init
[[ ! -e "$root/must-not-create" ]]
sed -i "s|^RESTIC_REPOSITORY=.*|RESTIC_REPOSITORY=$root/repository|" "$config"
# Validate writes hold state and must share the modifying-operation mutex.
(
  flock -n 8 || exit 1
  set +e
  run validate >/dev/null 2>&1
  result=$?
  set -e
  [[ $result -eq 75 ]]
) 8>"$root/operation.lock"
mkdir -p "$root/logs"
touch "$root/logs/expired.log"
touch -d '40 days ago' "$root/logs/expired.log"
run backup
[[ ! -e "$root/logs/expired.log" ]]
printf 'changed\n' >> "$source_dir/document-1.bin"
run backup
run retention
run check
run check-read-data
run status
sed -i 's/^MAX_SNAPSHOT_AGE_SECONDS=.*/MAX_SNAPSHOT_AGE_SECONDS=0/' "$config"
sleep 1
expect_failure status
sed -i 's/^MAX_SNAPSHOT_AGE_SECONDS=.*/MAX_SNAPSHOT_AGE_SECONDS=1800/' "$config"

# Partial loss crosses the enrolled session baseline, creates a durable hold,
# and cannot be cleared until the source has recovered.
mkdir "$root/deleted-sessions"
mv "$source_dir/.pi/agent/sessions/"{1,2,3}.jsonl "$root/deleted-sessions/"
expect_failure validate
[[ -s "$root/retention.hold" ]]
expect_failure retention
expect_failure clear-hold
mv "$root/deleted-sessions/"*.jsonl "$source_dir/.pi/agent/sessions/"
expect_failure retention # restoration alone must not clear the hold
run clear-hold
run retention

# A missing landmark (mass-loss signal) also persists a hold across invocation.
mv "$source_dir/.ssh/id_ed25519" "$root/id_ed25519"
expect_failure prune
[[ -s "$root/retention.hold" ]]
mv "$root/id_ed25519" "$source_dir/.ssh/id_ed25519"
expect_failure prune
run clear-hold

# Missing or malformed baseline state fails closed and creates the same hold.
cp "$root/source-baseline" "$root/source-baseline.good"
rm "$root/source-baseline"
expect_failure retention
[[ -s "$root/retention.hold" ]]
cp "$root/source-baseline.good" "$root/source-baseline"
run clear-hold
printf 'schema_version=99\n' > "$root/source-baseline"
expect_failure prune
[[ -s "$root/retention.hold" ]]
cp "$root/source-baseline.good" "$root/source-baseline"
run clear-hold

# A measurement can print plausible partial output and still fail. Neither
# direct maintenance entrypoint may proceed, and recovery must not erase hold.
mkdir "$root/fault-bin"
real_du=$(command -v du)
real_find=$(command -v find)
real_restic=$(command -v restic)
export FAULT_SOURCE=$source_dir FAULT_CALL_LOG=$root/maintenance-calls
export REAL_DU=$real_du REAL_FIND=$real_find REAL_RESTIC=$real_restic
cat > "$root/fault-bin/du" <<'FAULT'
#!/usr/bin/env bash
"$REAL_DU" "$@"
exit 1
FAULT
cat > "$root/fault-bin/find" <<'FAULT'
#!/usr/bin/env bash
"$REAL_FIND" "$@"
if [[ $1 == "$FAULT_SOURCE$FAULT_SUFFIX" ]]; then exit 1; fi
FAULT
cat > "$root/fault-bin/restic" <<'FAULT'
#!/usr/bin/env bash
if [[ $1 == forget || $1 == prune ]]; then printf '%s\n' "$1" >> "$FAULT_CALL_LOG"; exit 99; fi
exec "$REAL_RESTIC" "$@"
FAULT
chmod 755 "$root/fault-bin/"*
for failure in bytes files sessions; do
  if [[ $failure != bytes ]]; then rm -f "$root/fault-bin/du"; fi
  export FAULT_SUFFIX=''
  if [[ $failure == sessions ]]; then FAULT_SUFFIX=/.pi/agent/sessions; fi
  for operation in retention prune; do
    : > "$FAULT_CALL_LOG"
    PATH="$root/fault-bin:$PATH" expect_failure "$operation"
    [[ -s "$root/retention.hold" && ! -s "$FAULT_CALL_LOG" ]]
    expect_failure "$operation" # healthy measurement does not clear prior hold
    run clear-hold
  done
done

# Opening a Restic repository is insufficient: its identity must match the pin.
sed -i "s/^EXPECTED_REPOSITORY_ID=.*/EXPECTED_REPOSITORY_ID=${repository_id}bad/" "$config"
expect_failure status
sed -i "s/^EXPECTED_REPOSITORY_ID=.*/EXPECTED_REPOSITORY_ID=$repository_id/" "$config"

restore=$root/restore
run restore latest "$restore"
cmp "$source_dir/document-1.bin" "$restore${source_dir}/document-1.bin"
[[ $(sqlite3 "$restore${source_dir}/.local/share/mcfly/history.db.restic-backup" 'PRAGMA integrity_check;') == ok ]]

printf 'Restic home tests passed.\n'
