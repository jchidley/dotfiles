# shellcheck shell=bash
# One visible WSL login owns GPG prompting and the SSH unlock deadline.
# Source from .bashrc_custom; never from automation launchers.
credential_login_visible() {
    [[ -n ${WSL_DISTRO_NAME:-} && $- == *i* && -t 0 && -t 1 &&
       -n ${TERM:-} && $TERM != dumb ]]
}

credential_login_automatic() {
    credential_login_visible && shopt -q login_shell &&
        [[ -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]]
}

credential-unlock() {
    if ! credential_login_visible; then
        printf 'credential-unlock requires a visible interactive WSL terminal.\n' >&2
        return 1
    fi
    credential_login
}

credential_login_seconds() {
    local seconds rest
    read -r seconds rest </proc/uptime
    printf '%s\n' "${seconds%%.*}"
}

credential_login() {
    credential_login_visible || return 0
    local directory=${XDG_RUNTIME_DIR:-$HOME/.ssh}
    local key=${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}
    local ttl=${SSH_KEY_CACHE_TTL:-72000}
    local now deadline=0 boot saved_boot='' pid='' start='' saved_start='' lock_fd
    local record="$directory/credential-session"
    [[ $ttl =~ ^[1-9][0-9]*$ ]] && ((ttl <= 72000)) || return 1
    [[ -f $key && -x $HOME/.local/bin/ak ]] || return 0
    export GPG_TTY
    GPG_TTY=$(tty)
    credential_agent_start || return 1
    exec {lock_fd}>"$directory/credential-login.lock"
    if ! flock -n "$lock_fd"; then
        printf 'Another terminal is unlocking credentials; waiting for it (Ctrl-C to cancel).\n' >&2
        flock "$lock_fd" || { exec {lock_fd}>&-; return 1; }
    fi
    # Subshell guarantees release of the login lock even when a step fails.
    (
        boot=$(</proc/sys/kernel/random/boot_id)
        now=$(credential_login_seconds)
        if [[ -f $record ]]; then
            read -r saved_boot deadline pid saved_start <"$record" || deadline=0
            if [[ $pid =~ ^[0-9]+$ && -r /proc/$pid/stat ]]; then
                start=$(awk '{print $22}' "/proc/$pid/stat")
            fi
            if [[ $saved_boot != "$boot" || ! $deadline =~ ^[0-9]+$ ||
                  -z $start || $start != "$saved_start" ]]; then deadline=0; fi
        fi
        if ((now >= deadline)); then
            # Start one known cache window. Do not reuse an untracked older
            # GPG unlock and accidentally give SSH a later expiry.
            if credential_agent_key_loaded "$key"; then ssh-add -d "$key.pub" >/dev/null 2>&1 || exit 1; fi
            rm -f -- "$record" || exit 1
            gpgconf --kill gpg-agent || exit 1
            deadline=$((now + ttl))
            printf 'Unlock GPG for this login; SSH will share its maximum %s-second window.\n' "$ttl" >&2
            AK_INTERACTIVE_UNLOCK=1 "$HOME/.local/bin/ak" get ssh-key >/dev/null || exit 1
            pid=$(gpg-connect-agent 'GETINFO pid' /bye | awk '$1=="D" {print $2}') || exit 1
            [[ $pid =~ ^[0-9]+$ && -r /proc/$pid/stat ]] || exit 1
            start=$(awk '{print $22}' "/proc/$pid/stat")
        fi
        now=$(credential_login_seconds)
        ((deadline > now)) || { printf 'Unlock window expired; try a new login.\n' >&2; exit 1; }
        # Existing identities keep their expiry: opening a terminal cannot
        # refresh SSH beyond the original GPG login window.
        if ! credential_agent_key_loaded "$key"; then
            AK_INTERACTIVE_UNLOCK=0 SSH_KEY_CACHE_TTL=$((deadline - now)) credential_agent_load_ssh_key || exit 1
        fi
        temporary=$(mktemp "$directory/credential-session.XXXXXX") || exit 1
        chmod 600 "$temporary" || exit 1
        printf '%s %s %s %s\n' "$boot" "$deadline" "$pid" "$start" >"$temporary" || exit 1
        mv -f -- "$temporary" "$record" || exit 1
    )
    local status=$?
    flock -u "$lock_fd"
    exec {lock_fd}>&-
    return "$status"
}
