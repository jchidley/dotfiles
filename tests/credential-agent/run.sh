#!/bin/bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
ak_bin=$(command -v ak || true)
askpass_bin=$(command -v ak-ssh-askpass || true)
[[ -n $ak_bin ]] || ak_bin=$HOME/git/ak/bin/ak
[[ -n $askpass_bin ]] || askpass_bin=$HOME/git/ak/bin/ak-ssh-askpass
[[ -x $ak_bin && -x $askpass_bin ]]
work=$(mktemp -d)
agent_pid=
persistent_pid=
cleanup() {
    [[ -z ${agent_pid:-} ]] || kill "$agent_pid" 2>/dev/null || true
    [[ -z ${persistent_pid:-} ]] || kill "$persistent_pid" 2>/dev/null || true
    rm -rf "$work"
}
trap cleanup EXIT

export HOME=$work/home
export XDG_RUNTIME_DIR=$work/run
mkdir -p "$HOME/.ssh" "$XDG_RUNTIME_DIR"
unset SSH_AUTH_SOCK SSH_AGENT_PID
source "$repo/dot_local/lib/credential-agent.sh"

# An agent started by a shell remains reachable after that shell exits.
mkdir -p "$work/persistent-home/.ssh" "$work/persistent-run"
persistent_state=$(HOME="$work/persistent-home" XDG_RUNTIME_DIR="$work/persistent-run" \
    SSH_AGENT_SOCKET="$work/persistent-run/ssh-agent.sock" bash -c '
        source "$1"
        credential_agent_start
        printf "%s %s" "$SSH_AGENT_PID" "$SSH_AUTH_SOCK"
    ' _ "$repo/dot_local/lib/credential-agent.sh")
read -r persistent_pid persistent_socket <<<"$persistent_state"
SSH_AUTH_SOCK=$persistent_socket ssh-add -l >/dev/null 2>&1 || [[ $? == 1 ]]

# A live, empty agent is healthy and must be reused rather than replaced.
credential_agent_start
agent_pid=$SSH_AGENT_PID
agent_socket=$SSH_AUTH_SOCK
[[ $(ssh-add -l >/dev/null 2>&1; printf '%s' "$?") == 1 ]]
agent_count=$(pgrep -x ssh-agent | wc -l)
credential_agent_start
[[ -z ${SSH_AGENT_PID+x} ]]
[[ $SSH_AUTH_SOCK == "$agent_socket" ]]
[[ $(pgrep -x ssh-agent | wc -l) == "$agent_count" ]]

# The OpenSSH key is loaded through the real askpass -> `ak get ssh-key` path.
ssh-keygen -q -t ed25519 -N test-passphrase -f "$HOME/.ssh/id_ed25519"
mkdir -p "$work/bin"
cat >"$work/bin/ak" <<'AK'
#!/bin/sh
[ "$1" = get ] && [ "$2" = ssh-key ]
: >"$AK_MARKER"
printf '%s\n' test-passphrase
AK
chmod 700 "$work/bin/ak"
export AK_MARKER=$work/ak-called
PATH="$work/bin:$PATH" SSH_KEY_ASKPASS=$askpass_bin SSH_KEY_CACHE_TTL=1 credential_agent_load_ssh_key
[[ -f $AK_MARKER ]]
credential_agent_key_loaded "$HOME/.ssh/id_ed25519"
# A subsequent shell refreshes an existing identity's deadline.
PATH="$work/bin:$PATH" SSH_KEY_ASKPASS=$askpass_bin SSH_KEY_CACHE_TTL=3 credential_agent_load_ssh_key
sleep 2
credential_agent_key_loaded "$HOME/.ssh/id_ed25519"
sleep 2
! credential_agent_key_loaded "$HOME/.ssh/id_ed25519"
# Without ak/GPG decryption the expired identity cannot be restored.
cat >"$work/bin/ak" <<'AK_FAIL'
#!/bin/sh
exit 1
AK_FAIL
chmod 700 "$work/bin/ak"
if PATH="$work/bin:$PATH" SSH_KEY_ASKPASS=$askpass_bin credential_agent_load_ssh_key 2>/dev/null; then
    echo 'SSH identity loaded without ak credential access' >&2
    exit 1
fi
! credential_agent_key_loaded "$HOME/.ssh/id_ed25519"

# SSH passphrases remain explicitly retrievable for askpass but are never exportable.
mkdir -p "$work/ak/services" "$work/ak/secrets"
cat >"$work/ak/services/api.yaml" <<'YAML'
name: API
env_var: API_KEY
YAML
cat >"$work/ak/services/ssh-key.yaml" <<'YAML'
name: SSH
env_var: SSH_KEY_PASSPHRASE
export: false
YAML
: >"$work/ak/secrets/api.gpg"
: >"$work/ak/secrets/ssh-key.gpg"
cat >"$work/bin/gpg" <<'GPG'
#!/bin/sh
for last do :; done
case "$last" in
  */api.gpg) printf '%s' api-secret ;;
  */ssh-key.gpg) printf '%s' ssh-secret ;;
esac
GPG
chmod 700 "$work/bin/gpg"
bulk=$(PATH="$work/bin:$PATH" AK_DIR="$work/ak" "$ak_bin" export)
[[ $bulk == *"API_KEY="* ]]
[[ $bulk != *"SSH_KEY_PASSPHRASE"* ]]
if PATH="$work/bin:$PATH" AK_DIR="$work/ak" "$ak_bin" export ssh-key >/dev/null 2>&1; then
    echo 'Non-exportable SSH credential was explicitly exported' >&2
    exit 1
fi
explicit=$(PATH="$work/bin:$PATH" AK_DIR="$work/ak" "$ak_bin" get ssh-key)
[[ $explicit == ssh-secret ]]

printf '%s\n' 'credential-agent tests passed'
