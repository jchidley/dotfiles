#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'run this disposable test as root' >&2; exit 1; }
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(mktemp -d /var/tmp/restic-password-test.XXXXXX)
trap 'rm -rf "$root"' EXIT
mkdir "$root/bin" "$root/repository"
touch "$root/repository/config"
id=$(printf 'a%.0s' {1..64})
cat > "$root/home.conf" <<EOF
RESTIC_REPOSITORY=$root/repository
EXPECTED_REPOSITORY_ID=$id
RESTIC_PASSWORD=must-not-be-used
RESTIC_PASSWORD_FILE=$root/absent-runtime-password
RESTIC_PASSWORD_COMMAND=false
EOF
chmod 600 "$root/home.conf"
cat > "$root/bin/restic" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ ${RESTIC_PASSWORD+x} != x && ${RESTIC_PASSWORD_FILE+x} != x && ${RESTIC_PASSWORD_COMMAND+x} != x ]]
[[ $# == 6 && $1 == --repo && $2 == "$FIXTURE_ROOT/repository" && $3 == --password-file && $4 == /dev/fd/3 && $5 == cat && $6 == config ]]
IFS= read -r password < /dev/fd/3
[[ $password == fixture-recovery-value ]] || exit 1
printf '{"id":"%s"}\n' "$FIXTURE_ID"
EOF
chmod 755 "$root/bin/restic"
export FIXTURE_ROOT=$root FIXTURE_ID=$id RESTIC_HOME_CONFIG=$root/home.conf
export PATH="$root/bin:$PATH"
run_terminal() {
  # Only a disposable fixture value enters this PTY; never a production secret.
  printf '%s\n' "$1" | script --quiet --return --echo never \
    --command "bash '$SCRIPT_DIR/test-restic-recovery-password'" /dev/null > "$root/output" 2>&1
}
run_terminal fixture-recovery-value
grep -q 'recovery_password_test=passed' "$root/output"
if grep -q fixture-recovery-value "$root/output"; then echo 'fixture password leaked' >&2; exit 1; fi
if run_terminal wrong-value; then echo 'wrong password accepted' >&2; exit 1; fi
FIXTURE_ID=$(printf 'b%.0s' {1..64})
export FIXTURE_ID
if run_terminal fixture-recovery-value; then echo 'wrong repository accepted' >&2; exit 1; fi
grep -q 'repository identity mismatch' "$root/output"
chmod 666 "$root/home.conf"
if run_terminal fixture-recovery-value; then echo 'writable configuration accepted' >&2; exit 1; fi
grep -q 'configuration must not be group/world-writable' "$root/output"
chmod 600 "$root/home.conf"
rm "$root/home.conf"
if run_terminal fixture-recovery-value; then echo 'missing configuration accepted' >&2; exit 1; fi
grep -q 'configuration is not readable' "$root/output"
printf 'Recovery-password PTY tests passed.\n'
