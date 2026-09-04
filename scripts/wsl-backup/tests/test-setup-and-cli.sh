#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/wsl-backup-shell-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
FAKEBIN=$TMP/bin
CALL_LOG=$TMP/calls.log
mkdir -p "$FAKEBIN"
: > "$CALL_LOG"
export CALL_LOG

fail() { echo "ASSERTION FAILED: $*" >&2; exit 1; }
assert_file() { [[ -f "$1" ]] || fail "missing file: $1"; }
assert_log() { grep -F -- "$1" "$CALL_LOG" >/dev/null || fail "log does not contain: $1"; }
assert_not_log() { ! grep -F -- "$1" "$CALL_LOG" >/dev/null || fail "log unexpectedly contains: $1"; }

for name in restic sqlite3; do
  cat > "$FAKEBIN/$name" <<'FAKE'
#!/usr/bin/env bash
exit 0
FAKE
  chmod +x "$FAKEBIN/$name"
done

cat > "$FAKEBIN/fake-wslpath" <<'FAKE'
#!/usr/bin/env bash
[[ ${1:-} == -w && $# -eq 2 ]] || exit 2
printf 'C:\\fixture%s\n' "${2//\//\\}"
FAKE
chmod +x "$FAKEBIN/fake-wslpath"

cat > "$FAKEBIN/fake-powershell" <<'FAKE'
#!/usr/bin/env bash
printf 'powershell' >> "$CALL_LOG"
printf ' <%s>' "$@" >> "$CALL_LOG"
printf '\n' >> "$CALL_LOG"
system_command=0
for arg in "$@"; do
  if [[ $arg == *'Join-Path $env:LOCALAPPDATA'* ]]; then
    printf 'C:\\Fixture User\\AppData\\Local\\WSLBackup\\system\\Backup-WslSystem.ps1'
  elif [[ $arg == -Mode ]]; then
    system_command=1
  fi
done
if ((system_command)); then
  printf 'fixture PowerShell output\r\n'
  if [[ -n ${POWERSHELL_STDERR:-} ]]; then
    printf '%s\r\n' "$POWERSHELL_STDERR" >&2
  fi
fi
exit "${POWERSHELL_EXIT:-0}"
FAKE
chmod +x "$FAKEBIN/fake-powershell"

# Installation is isolated under DESTDIR and does not require sudo.
install_root=$TMP/install
PATH="$FAKEBIN:$PATH" WSL_BACKUP_DESTDIR=$install_root \
  "$ROOT/setup.sh" --no-windows-tasks >/dev/null
assert_file "$install_root/usr/local/bin/wsl-backup"
assert_file "$install_root/usr/local/sbin/backup-wsl-home"
assert_file "$install_root/usr/local/sbin/validate-wsl-system-restore"
assert_file "$install_root/etc/restic/home.conf"
assert_file "$install_root/usr/local/sbin/wsl-home-scheduler"
assert_file "$install_root/etc/systemd/system/wsl-home-scheduler.service"
assert_file "$install_root/etc/systemd/system/wsl-home-scheduler.timer"
[[ ! -e "$ROOT/home/Register-WindowsTasks.ps1" ]] || fail 'obsolete Register-WindowsTasks.ps1 remains in active source'
! grep -Eq 'systemctl +(enable|start)|enable +--now' "$ROOT/setup.sh" || fail 'ordinary setup implicitly enables Linux scheduling'

# Windows controller installation is independent; routine scheduling remains Linux-owned.
: > "$CALL_LOG"
PATH="$FAKEBIN:$PATH" WSL_BACKUP_DESTDIR=$install_root \
  WSL_BACKUP_POWERSHELL="$FAKEBIN/fake-powershell" \
  WSL_BACKUP_WSLPATH="$FAKEBIN/fake-wslpath" \
  "$ROOT/setup.sh" --distro 'Fixture Distro' >/dev/null 2> "$TMP/setup-warning"
assert_file "$install_root/etc/wsl-backup/windows-system-script"
assert_log 'Install-Windows.ps1'
assert_not_log 'Register-WindowsTasks.ps1'
grep -F 'timer was installed but not enabled' "$TMP/setup-warning" >/dev/null || fail 'missing repository warning'

# One repository landmark is insufficient; both are required.
printf 'fixture\n' > "$install_root/etc/restic/home.password"
: > "$CALL_LOG"
PATH="$FAKEBIN:$PATH" WSL_BACKUP_DESTDIR=$install_root \
  WSL_BACKUP_POWERSHELL="$FAKEBIN/fake-powershell" \
  WSL_BACKUP_WSLPATH="$FAKEBIN/fake-wslpath" \
  "$ROOT/setup.sh" --distro 'Fixture Distro' >/dev/null 2> /dev/null
assert_not_log 'Register-WindowsTasks.ps1'

# Once both repository landmarks exist, setup still never registers Windows home tasks.
mkdir -p "$install_root/var/lib/restic/home"
printf '{}\n' > "$install_root/var/lib/restic/home/config"
: > "$CALL_LOG"
PATH="$FAKEBIN:$PATH" WSL_BACKUP_DESTDIR=$install_root \
  WSL_BACKUP_POWERSHELL="$FAKEBIN/fake-powershell" \
  WSL_BACKUP_WSLPATH="$FAKEBIN/fake-wslpath" \
  "$ROOT/setup.sh" --distro 'Fixture Distro' >/dev/null
assert_not_log 'Register-WindowsTasks.ps1'
if PATH="$FAKEBIN:$PATH" WSL_BACKUP_DESTDIR=$install_root \
    WSL_BACKUP_POWERSHELL="$FAKEBIN/fake-powershell" \
    WSL_BACKUP_WSLPATH="$FAKEBIN/fake-wslpath" \
    "$ROOT/setup.sh" --distro 'Fixture Distro' --force-windows-tasks >/dev/null 2>&1; then
  fail 'retired Windows task force option was accepted'
fi

if PATH="$FAKEBIN:$PATH" WSL_BACKUP_DESTDIR=$TMP/bad \
    "$ROOT/setup.sh" --no-windows-tasks --distro 'bad"name' >/dev/null 2>&1; then
  fail 'invalid distro name was accepted'
fi

cat > "$FAKEBIN/fake-home" <<'FAKE'
#!/usr/bin/env bash
printf 'home' >> "$CALL_LOG"
printf ' <%s>' "$@" >> "$CALL_LOG"
printf '\n' >> "$CALL_LOG"
exit "${HOME_EXIT:-0}"
FAKE
chmod +x "$FAKEBIN/fake-home"
cat > "$FAKEBIN/fake-sudo" <<'FAKE'
#!/usr/bin/env bash
printf 'sudo <%s>\n' "$*" >> "$CALL_LOG"
exec "$@"
FAKE
chmod +x "$FAKEBIN/fake-sudo"
controller_config=$TMP/'controller path.conf'
printf 'C:\\Fixture User\\WSLBackup\\Backup-WslSystem.ps1\n' > "$controller_config"

run_cli() {
  PATH="$FAKEBIN:$PATH" \
  WSL_BACKUP_HOME_COMMAND="$FAKEBIN/fake-home" \
  WSL_BACKUP_SUDO="$FAKEBIN/fake-sudo" \
  WSL_BACKUP_POWERSHELL="$FAKEBIN/fake-powershell" \
  WSL_BACKUP_SYSTEM_SCRIPT_CONFIG="$controller_config" \
  "$ROOT/wsl-backup" "$@"
}

: > "$CALL_LOG"
run_cli home snapshots >/dev/null
assert_log 'home <snapshots>'
: > "$CALL_LOG"
system_output=$(run_cli system Preflight)
assert_log '<-Mode> <Preflight>'
assert_log '<C:\Fixture User\WSLBackup\Backup-WslSystem.ps1>'
[[ $system_output == 'fixture PowerShell output' ]] || fail "PowerShell output was not normalized: $(printf %q "$system_output")"
system_error=$TMP/system-error
POWERSHELL_STDERR='fixture PowerShell error' run_cli system Status >/dev/null 2> "$system_error"
[[ $(<"$system_error") == 'fixture PowerShell error' ]] || fail "PowerShell error output was not normalized: $(printf %q "$(<"$system_error")")"
: > "$CALL_LOG"
run_cli status >/dev/null
assert_log 'home <status>'
assert_log '<-Mode> <Status>'
if run_cli unknown >/dev/null 2>&1; then fail 'unknown command was accepted'; fi

set +e
HOME_EXIT=7 run_cli home backup >/dev/null 2>&1
code=$?
set -e
[[ $code -eq 7 ]] || fail "home exit code was not preserved: $code"

set +e
POWERSHELL_EXIT=9 run_cli system Status >/dev/null 2>&1
code=$?
set -e
[[ $code -eq 9 ]] || fail "PowerShell exit code was not preserved through output normalization: $code"

printf 'WSL backup setup/CLI tests passed.\n'
