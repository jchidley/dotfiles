# Shared GPG/ak-backed SSH credential setup for interactive WSL shells.
# Source this file; do not execute it.

credential_agent_socket_alive() {
    local socket=${1:-} status
    [[ -S $socket ]] || return 1
    if SSH_AUTH_SOCK=$socket ssh-add -l >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi
    # ssh-add returns 1 for a live agent with no identities and 2 for no agent.
    [[ $status == 0 || $status == 1 ]]
}

credential_agent_start() {
    command -v ssh-agent >/dev/null 2>&1 || return 0
    command -v ssh-add >/dev/null 2>&1 || return 0

    local agent_dir=${XDG_RUNTIME_DIR:-$HOME/.ssh}
    local agent_socket=${SSH_AGENT_SOCKET:-$agent_dir/ssh-agent.sock}
    local lock_file=$agent_dir/ssh-agent.lock
    local lock_fd
    mkdir -p -m 0700 "$agent_dir"

    # Local WSL shells use the fixed persistent socket. Preserve an explicitly
    # forwarded agent only inside an inbound SSH session.
    if credential_agent_socket_alive "$agent_socket"; then
        SSH_AUTH_SOCK=$agent_socket
        unset SSH_AGENT_PID
        export SSH_AUTH_SOCK
        return 0
    fi
    if [[ -n ${SSH_CONNECTION:-} ]] && credential_agent_socket_alive "${SSH_AUTH_SOCK:-}"; then
        unset SSH_AGENT_PID
        export SSH_AUTH_SOCK
        return 0
    fi

    # Serialize first-shell startup so concurrent terminals cannot orphan agents.
    exec {lock_fd}>"$lock_file"
    flock "$lock_fd"
    if credential_agent_socket_alive "$agent_socket"; then
        SSH_AUTH_SOCK=$agent_socket
        unset SSH_AGENT_PID
        export SSH_AUTH_SOCK
    else
        rm -f "$agent_socket"
        eval "$(ssh-agent -s -a "$agent_socket")" >/dev/null
        export SSH_AUTH_SOCK SSH_AGENT_PID
    fi
    flock -u "$lock_fd"
    exec {lock_fd}>&-
}

credential_agent_key_loaded() {
    local key=${1:-$HOME/.ssh/id_ed25519}
    local public_key
    [[ -r $key.pub ]] || return 1
    read -r _ public_key _ <"$key.pub"
    [[ -n $public_key ]] || return 1
    ssh-add -L 2>/dev/null | awk -v wanted="$public_key" '$2 == wanted { found=1 } END { exit !found }'
}

credential_agent_load_ssh_key() {
    local key=${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}
    local askpass=${SSH_KEY_ASKPASS:-$HOME/.local/bin/ak-ssh-askpass}
    local ttl=${SSH_KEY_CACHE_TTL:-72000}
    local error_file status

    [[ -f $key && -x $askpass ]] || return 0
    credential_agent_socket_alive "${SSH_AUTH_SOCK:-}" || return 1

    # Re-adding an existing identity refreshes its deadline. This prevents a
    # new long-running task from inheriting a key with only minutes remaining.
    error_file=$(mktemp)
    if DISPLAY=${DISPLAY:-:0} SSH_ASKPASS=$askpass SSH_ASKPASS_REQUIRE=force \
        ssh-add -t "$ttl" "$key" </dev/null >/dev/null 2>"$error_file"; then
        status=0
    else
        status=$?
    fi
    if [[ $status != 0 ]]; then
        printf 'SSH key auto-load failed: %s\n' "$(<"$error_file")" >&2
    fi
    rm -f "$error_file"
    return "$status"
}
