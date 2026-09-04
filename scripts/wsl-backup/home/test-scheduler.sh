#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(mktemp -d "${TMPDIR:-/tmp}/wsl-home-scheduler-test.XXXXXX")
trap 'rm -rf "$root"' EXIT
assertions=0
fail() { echo "ASSERTION FAILED: $*" >&2; exit 1; }
assert() { assertions=$((assertions + 1)); "$@" || fail "$*"; }
assert_equal() { assertions=$((assertions + 1)); [[ $2 == "$1" ]] || fail "$3"; }

scheduler=${WSL_HOME_SCHEDULER_CANDIDATE:-$SCRIPT_DIR/wsl-home-scheduler}
log=$root/operations.log
control=$root/control
mkdir -p "$control"
fake=$root/fake-home
cat > "$fake" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
operation=${1:?}
printf '%s\n' "$operation" >> "$TEST_OPERATION_LOG"
exit_file=$TEST_CONTROL_DIR/$operation.exit
if [[ -e $exit_file ]]; then exit "$(<"$exit_file")"; fi
FAKE
chmod +x "$fake"

run_scheduler() {
  local name=$1 now=$2
  shift 2
  TEST_OPERATION_LOG=$log TEST_CONTROL_DIR=$control \
    WSL_HOME_SCHEDULER_COMMAND=$fake \
    WSL_HOME_SCHEDULER_STATE_DIR=$root/$name-state \
    WSL_HOME_SCHEDULER_LOCK_PATH=$root/$name.lock \
    WSL_HOME_SCHEDULER_NOW_EPOCH=$now \
    WSL_HOME_RETENTION_INTERVAL_SECONDS=86400 \
    "$scheduler" "$@"
}

mkdir -p "$root/malformed-state"
printf 'schema_version=99\nlast_retention_success_epoch=0\n' > "$root/malformed-state/state"
: > "$log"
set +e
run_scheduler malformed 200000 >/dev/null 2>&1
code=$?
set -e
assert_equal 1 "$code" 'malformed scheduler state fails closed before backup'
assert test ! -s "$log"

: > "$log"
run_scheduler normal 100000
assert grep -Fxq backup "$log"
assert grep -Fxq status "$log"
assert grep -Fxq retention "$log"
assert test "$(paste -sd, "$log")" = 'backup,status,retention'
assert grep -Fxq schema_version=1 "$root/normal-state/state"
assert grep -Fxq last_retention_success_epoch=100000 "$root/normal-state/state"

: > "$log"
run_scheduler normal 186399
assert_equal 'backup,status' "$(paste -sd, "$log")" 'retention remains not due before its exact Linux-owned boundary'
assert grep -Fxq last_retention_success_epoch=100000 "$root/normal-state/state"
: > "$log"
run_scheduler normal 186400
assert test "$(paste -sd, "$log")" = 'backup,status,retention'
assert grep -Fxq last_retention_success_epoch=186400 "$root/normal-state/state"

printf '2\n' > "$control/backup.exit"
: > "$log"
set +e
run_scheduler failed-backup 200000 >/dev/null 2>&1
code=$?
set -e
assert_equal 2 "$code" 'backup failure propagates and blocks all later Linux-owned work'
assert_equal backup "$(paste -sd, "$log")" 'backup failure invokes no status or maintenance'
assert test ! -e "$root/failed-backup-state/state"
rm "$control/backup.exit"

printf '75\n' > "$control/backup.exit"
: > "$log"
set +e
run_scheduler deferred-backup 200000 >/dev/null 2>&1
code=$?
set -e
assert test "$code" -eq 75
assert test "$(paste -sd, "$log")" = 'backup'
rm "$control/backup.exit"

printf '3\n' > "$control/status.exit"
: > "$log"
set +e
run_scheduler failed-status 200000 >/dev/null 2>&1
code=$?
set -e
assert test "$code" -eq 3
assert test "$(paste -sd, "$log")" = 'backup,status'
assert test ! -e "$root/failed-status-state/state"
rm "$control/status.exit"

printf '4\n' > "$control/retention.exit"
: > "$log"
set +e
run_scheduler failed-retention 200000 >/dev/null 2>&1
code=$?
set -e
assert test "$code" -eq 4
assert test "$(paste -sd, "$log")" = 'backup,status,retention'
assert test ! -e "$root/failed-retention-state/state"
rm "$control/retention.exit"

ready=$root/lock-ready
(flock -x 8; touch "$ready"; sleep 10) 8>"$root/overlap.lock" &
holder=$!
while [[ ! -e $ready ]]; do sleep 0.02; done
set +e
run_scheduler overlap 200000 >/dev/null 2>&1
code=$?
set -e
kill "$holder" 2>/dev/null || true
wait "$holder" 2>/dev/null || true
assert_equal 75 "$code" 'overlap refusal runs no second Linux coordinator'

assert_equal '' "$(find "$root" -name '.state.*' -print -quit)" 'atomic scheduler state writes leave no temporary file'
if grep -Eiq 'wsl\.exe|pwsh|powershell|scheduledtask' "$scheduler"; then
  fail 'Linux scheduler contains a Windows execution boundary'
fi
assertions=$((assertions + 1))
unit_dir=$SCRIPT_DIR/systemd
assert grep -Fxq 'ExecStart=/usr/local/sbin/wsl-home-scheduler' "$unit_dir/wsl-home-scheduler.service"
assert grep -Fxq 'OnBootSec=2min' "$unit_dir/wsl-home-scheduler.timer"
assert grep -Fxq 'OnUnitActiveSec=15min' "$unit_dir/wsl-home-scheduler.timer"
assert grep -Fxq 'Persistent=true' "$unit_dir/wsl-home-scheduler.timer"
printf 'WslHomeLinuxScheduler retained tests passed: %d assertions\n' "$assertions"
