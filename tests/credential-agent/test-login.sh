#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d /var/tmp/credential-login-test.XXXXXX)
trap 'rm -rf -- "$work"' EXIT
export HOME="$work/home" XDG_RUNTIME_DIR="$work/run" WSL_DISTRO_NAME=fixture
mkdir -p "$HOME/.ssh" "$HOME/.local/bin" "$XDG_RUNTIME_DIR"
touch "$HOME/.ssh/id_ed25519"
source "$repo/dot_local/lib/credential-login.sh"
# Exercise real visibility classification under a PTY, without a real profile.
cat >"$work/visibility" <<EOF
source '$repo/dot_local/lib/credential-login.sh'
if credential_login_visible; then echo LOGIN_VISIBLE; else echo LOGIN_HIDDEN; fi
if credential_login_automatic; then echo LOGIN_AUTO; else echo LOGIN_MANUAL; fi
if [[ \${TEST_EXPLICIT:-0} == 1 ]]; then
  credential_login() { echo EXPLICIT_UNLOCK; }
  credential-unlock
fi
exit
EOF
TERM=dumb script -q -e -c "bash --noprofile --norc -i $work/visibility" /dev/null </dev/null >"$work/hidden"
TERM=xterm-256color script -q -e -c "bash --noprofile --norc -i $work/visibility" /dev/null </dev/null >"$work/visible"
TERM=xterm-256color bash --noprofile --norc "$work/visibility" >"$work/headless"
grep -q LOGIN_HIDDEN "$work/hidden"
grep -q LOGIN_VISIBLE "$work/visible"
grep -q LOGIN_HIDDEN "$work/headless"
grep -q LOGIN_MANUAL "$work/visible"
TERM=xterm-256color script -q -e -c "bash --noprofile --norc -li $work/visibility" /dev/null </dev/null >"$work/login"
grep -q LOGIN_AUTO "$work/login"
TERM=dumb script -q -e -c "bash --noprofile --norc -li $work/visibility" /dev/null </dev/null >"$work/hidden-login"
grep -q LOGIN_MANUAL "$work/hidden-login"
SSH_CONNECTION=fixture TERM=xterm-256color TEST_EXPLICIT=1 script -q -e -c "bash --noprofile --norc -li $work/visibility" /dev/null </dev/null >"$work/ssh"
grep -q LOGIN_MANUAL "$work/ssh"
grep -q EXPLICIT_UNLOCK "$work/ssh"
TERM=xterm-256color TEST_EXPLICIT=1 script -q -e -c "bash --noprofile --norc -i $work/visibility" /dev/null </dev/null >"$work/explicit"
grep -q EXPLICIT_UNLOCK "$work/explicit"

# Test session state and deadline logic independently of real secret stores.
credential_login_visible() { return 0; }
credential_login_seconds() { printf '%s\n' "$TEST_NOW"; }
tty() { printf '/dev/pts/fixture\n'; }
credential_agent_start() { return 0; }
credential_agent_key_loaded() { [[ -f $work/loaded ]]; }
credential_agent_load_ssh_key() {
  [[ ${AK_INTERACTIVE_UNLOCK:-} == 0 ]] || return 1
  printf '%s\n' "$SSH_KEY_CACHE_TTL" >>"$work/loads"
  touch "$work/loaded"
}
ssh-add() { [[ $1 == -d ]] || return 1; rm -f "$work/loaded"; }
gpgconf() { [[ $* == '--kill gpg-agent' ]] || return 1; echo reset >>"$work/resets"; }
gpg-connect-agent() { printf 'D %s\nOK\n' "$$"; }
export TEST_WORK="$work" TEST_UNLOCK_FAIL=0 TEST_UNLOCK_SLEEP=0
cat >"$HOME/.local/bin/ak" <<'AK'
#!/usr/bin/env bash
[[ $* == 'get ssh-key' && ${AK_INTERACTIVE_UNLOCK:-} == 1 ]] || exit 1
echo unlock >>"$TEST_WORK/unlocks"
sleep "$TEST_UNLOCK_SLEEP"
[[ $TEST_UNLOCK_FAIL == 0 ]] || exit 1
printf 'synthetic-password\n'
AK
chmod 700 "$HOME/.local/bin/ak"
SSH_KEY_CACHE_TTL=20
TEST_NOW=100
credential_login
[[ $(<"$work/loads") == 20 ]]
TEST_NOW=110
credential_login
[[ $(wc -l <"$work/loads") == 1 && $(wc -l <"$work/unlocks") == 1 ]]
rm "$work/loaded"
TEST_NOW=115
credential_login
[[ $(tail -n 1 "$work/loads") == 5 ]]
TEST_NOW=121
credential_login
[[ $(wc -l <"$work/unlocks") == 2 && $(tail -n 1 "$work/loads") == 20 ]]

# A cancelled unlock cannot mark the session unlocked or load SSH.
TEST_NOW=142
TEST_UNLOCK_FAIL=1
if credential_login; then echo 'cancelled unlock accepted' >&2; exit 1; fi
[[ ! -e $work/loaded && ! -e $XDG_RUNTIME_DIR/credential-session ]]
TEST_UNLOCK_FAIL=0
credential_login
[[ -f $work/loaded ]]

# Concurrent logins serialize the unlock, without refreshing the second key.
TEST_NOW=163
TEST_UNLOCK_SLEEP=1
before=$(wc -l <"$work/unlocks")
credential_login & first=$!
credential_login & second=$!
wait "$first"; wait "$second"
[[ $(wc -l <"$work/unlocks") == $((before+1)) ]]
printf 'PASS: hidden/headless refusal, fixed deadline, remaining SSH TTL, expiry, cancellation and concurrent login\n'
