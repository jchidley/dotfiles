#!/usr/bin/env bash
# Real agents and PTY; all keys, passphrases and pinentry are disposable fixtures.
set -euo pipefail
[[ $# -eq 1 ]] || { echo 'usage: test-login-real.sh AK_BINARY' >&2; exit 1; }
repo=$(cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d /var/tmp/credential-login-real.XXXXXX)
export HOME="$work/home" GNUPGHOME="$work/gnupg" XDG_RUNTIME_DIR="$work/run"
export AK_DIR="$work/vault" TEST_WORK="$work" TEST_REPO="$repo" TEST_AK_BINARY
TEST_AK_BINARY=$(realpath -e "$1")
cleanup() {
  gpgconf --kill gpg-agent
  if [[ -f $work/ssh-pid ]]; then kill "$(<"$work/ssh-pid")" 2>/dev/null || true; fi
  rm -rf -- "$work"
}
trap cleanup EXIT
mkdir -p "$HOME/.ssh" "$HOME/.local/bin" "$GNUPGHOME" "$XDG_RUNTIME_DIR" "$AK_DIR/secrets"
chmod 700 "$HOME" "$HOME/.ssh" "$GNUPGHOME" "$XDG_RUNTIME_DIR" "$AK_DIR" "$AK_DIR/secrets"
unset SSH_AUTH_SOCK SSH_AGENT_PID
cat >"$work/pinentry" <<'PIN'
#!/usr/bin/env bash
printf 'OK\n'
while IFS= read -r request; do
  case "$request" in
    GETPIN*) echo prompt >>"$TEST_WORK/prompts"; printf 'D synthetic-gpg-passphrase\nOK\n' ;;
    BYE*) printf 'OK\n'; exit 0 ;;
    *) printf 'OK\n' ;;
  esac
done
PIN
chmod 700 "$work/pinentry"
printf 'pinentry-program %s\ndefault-cache-ttl 5\nmax-cache-ttl 5\n' "$work/pinentry" >"$GNUPGHOME/gpg-agent.conf"
printf 'synthetic-gpg-passphrase\n' | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
  --quick-generate-key 'Disposable Login Test' rsa2048 encr 0 >/dev/null 2>&1
ssh-keygen -q -t ed25519 -N synthetic-ssh-passphrase -f "$HOME/.ssh/id_ed25519"
printf 'synthetic-ssh-passphrase\n' | gpg --batch --trust-model always --recipient 'Disposable Login Test' \
  --encrypt --output "$AK_DIR/secrets/ssh-key.gpg"
cat >"$HOME/.local/bin/ak" <<'AK'
#!/usr/bin/env bash
exec bash "$TEST_AK_BINARY" "$@"
AK
cat >"$HOME/.local/bin/ak-ssh-askpass" <<'ASK'
#!/usr/bin/env bash
exec bash "$TEST_AK_BINARY" get ssh-key
ASK
chmod 700 "$HOME/.local/bin/ak" "$HOME/.local/bin/ak-ssh-askpass"
cat >"$work/login" <<'LOGIN'
set -euo pipefail
source "$TEST_REPO/dot_local/lib/credential-agent.sh"
source "$TEST_REPO/dot_local/lib/credential-login.sh"
export WSL_DISTRO_NAME=fixture SSH_KEY_CACHE_TTL=5
credential_login
printf '%s\n' "$SSH_AGENT_PID" >"$TEST_WORK/ssh-pid"
credential_agent_key_loaded
[[ $(wc -l <"$TEST_WORK/prompts") == 1 ]]
sleep 1
credential_login
[[ $(wc -l <"$TEST_WORK/prompts") == 1 ]]
sleep 5
if credential_agent_key_loaded; then echo 'SSH survived its login deadline' >&2; exit 1; fi
if "$HOME/.local/bin/ak" get ssh-key >/dev/null 2>&1; then echo 'GPG survived its cache deadline' >&2; exit 1; fi
[[ $(wc -l <"$TEST_WORK/prompts") == 1 ]]
credential_login
credential_agent_key_loaded
[[ $(wc -l <"$TEST_WORK/prompts") == 2 ]]
printf 'PASS: real GPG and SSH, one prompt, no login refresh, expiry and next-login unlock\n'
exit
LOGIN
TERM=xterm-256color script -q -e -c "bash --noprofile --norc -i $work/login" /dev/null </dev/null
