#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 1 ]] || { echo 'usage: test-ak-prompt-policy.sh AK_BINARY' >&2; exit 1; }
export TEST_AK_BINARY
TEST_AK_BINARY=$(realpath -e "$1")
work=$(mktemp -d /var/tmp/ak-prompt-policy.XXXXXX)
trap 'rm -rf -- "$work"' EXIT
export AK_DIR="$work/vault" TEST_GPG_ARGS="$work/arguments"
mkdir -p "$AK_DIR/secrets" "$work/bin"
touch "$AK_DIR/secrets/ssh-key.gpg"
cat >"$work/bin/gpg" <<'GPG'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$TEST_GPG_ARGS"
printf 'synthetic-secret\n'
GPG
chmod 700 "$work/bin/gpg"
export PATH="$work/bin:$PATH"
TERM=xterm-256color bash "$TEST_AK_BINARY" get ssh-key >"$work/result"
grep -qx error "$TEST_GPG_ARGS"
# Even an inherited opt-in cannot authorize a hidden terminal's prompt.
TERM=dumb AK_INTERACTIVE_UNLOCK=1 GPG_TTY=/dev/pts/0 bash "$TEST_AK_BINARY" get ssh-key >"$work/result"
grep -qx error "$TEST_GPG_ARGS"
cat >"$work/visible" <<'VISIBLE'
export GPG_TTY
GPG_TTY=$(tty)
AK_INTERACTIVE_UNLOCK=1 bash "$TEST_AK_BINARY" get ssh-key >/dev/null
VISIBLE
TERM=xterm-256color script -q -e -c "bash $work/visible" /dev/null </dev/null >"$work/pty.log"
grep -qx ask "$TEST_GPG_ARGS"
printf 'PASS: AK defaults to cached-only access; only visible login opt-in can request pinentry\n'
