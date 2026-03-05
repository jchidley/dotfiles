#!/bin/bash
# Import McFly history from encrypted backups

set -euo pipefail

get_chezmoi_dir() {
    if command -v chezmoi >/dev/null 2>&1; then
        local dir
        dir="$(chezmoi source-path 2>/dev/null || true)"
        if [ -n "$dir" ]; then
            echo "$dir"
            return
        fi
    fi
    echo "$HOME/.local/share/chezmoi"
}

get_password() {
    local pw=""
    if command -v bw >/dev/null 2>&1; then
        pw="$(bw get password "bashrc-pgp" 2>/dev/null || true)"
    fi

    if [ -z "$pw" ]; then
        read -r -s -p "Password: " pw
        echo
    fi

    echo "$pw"
}

entry_count() {
    if [ ! -f "$MCFLY_DB" ]; then
        echo 0
        return
    fi

    local count
    count="$(mcfly stats 2>/dev/null | awk '/contains/{print $6; exit}' | tr -cd '0-9')"
    echo "${count:-0}"
}

MCFLY_DB="$HOME/.local/share/mcfly/history.db"
CHEZMOI_DIR="$(get_chezmoi_dir)"
ENCRYPTED_DIR="$CHEZMOI_DIR/mcfly_backups"
CURRENT_MACHINE="$(hostname)_$(cat /etc/machine-id 2>/dev/null | head -c 8 || echo "unknown")"

command -v mcfly >/dev/null 2>&1 || { echo "✗ McFly not installed"; exit 1; }
command -v gpg >/dev/null 2>&1 || { echo "✗ gpg is required"; exit 1; }

import() {
    local machine="$1"
    local file="$ENCRYPTED_DIR/encrypted_mcfly_${machine}.db.gpg"
    [ ! -f "$file" ] && { echo "✗ File not found: $file"; return 1; }

    local password
    password="$(get_password)"

    # Fast path: empty database (safe overwrite)
    local count
    count="$(entry_count)"
    if [ "$count" -eq 0 ]; then
        mkdir -p "$(dirname "$MCFLY_DB")"
        gpg --batch --yes --passphrase "$password" --decrypt "$file" > "$MCFLY_DB" 2>/dev/null &&
            echo "✓ Imported from $machine (fast)" && return 0 || {
            echo "✗ Decrypt failed"
            return 1
        }
    fi

    # Merge path: requires sqlite3
    command -v sqlite3 >/dev/null 2>&1 || {
        echo "✗ sqlite3 is required to merge into a non-empty McFly database"
        echo "  Install sqlite3, or clean/reset the DB first to use fast import"
        return 1
    }

    local temp_db="/tmp/mcfly_$(date +%s).db"
    cp "$MCFLY_DB" "$MCFLY_DB.backup.$(date +%Y%m%d_%H%M%S)"

    if gpg --batch --yes --passphrase "$password" --decrypt "$file" > "$temp_db" 2>/dev/null; then
        local before after
        before="$(entry_count)"
        echo "Merging from $machine (before: $before items)..."

        sqlite3 "$MCFLY_DB" "
        ATTACH '$temp_db' AS src;
        INSERT OR IGNORE INTO commands (cmd, cmd_tpl, session_id, when_run, exit_code, selected, dir, old_dir)
        SELECT cmd, cmd_tpl, session_id, when_run, exit_code, selected, dir, old_dir FROM src.commands
        WHERE NOT EXISTS (
            SELECT 1 FROM commands
            WHERE commands.cmd = src.commands.cmd
              AND commands.dir = src.commands.dir
              AND commands.when_run = src.commands.when_run
        );
        DETACH src;"

        after="$(entry_count)"
        echo "✓ Added $((after - before)) entries from $machine"
        rm -f "$temp_db"
    else
        echo "✗ Decrypt failed"
        return 1
    fi
}

# Get available exports
shopt -s nullglob
files=("$ENCRYPTED_DIR"/encrypted_mcfly_*.db.gpg)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No exports found in $ENCRYPTED_DIR"
    exit 0
fi

MACHINES=()
for file in "${files[@]}"; do
    base="$(basename "$file")"
    machine="${base#encrypted_mcfly_}"
    MACHINES+=("${machine%.db.gpg}")
done

IFS=$'\n' read -r -d '' -a MACHINES < <(printf '%s\n' "${MACHINES[@]}" | sort && printf '\0')
unset IFS

echo "McFly Import (current: $CURRENT_MACHINE)"
echo ""

while true; do
    for i in "${!MACHINES[@]}"; do
        [ "${MACHINES[$i]}" = "$CURRENT_MACHINE" ] && def=" (default)" || def=""
        echo "$((i + 1))) ${MACHINES[$i]}$def"
    done
    echo "c) Clean/Reset database"
    echo "t) Create test database"
    echo "q) Quit"
    read -r -p "> " choice

    [[ "$choice" =~ ^[qQ]$ ]] && exit 0

    [[ "$choice" =~ ^[tT]$ ]] && {
        [ -f "$MCFLY_DB" ] && cp "$MCFLY_DB" "$MCFLY_DB.backup.$(date +%Y%m%d_%H%M%S)"
        rm -f "$MCFLY_DB"
        touch /tmp/empty_history
        HISTFILE=/tmp/empty_history mcfly add --exit 0 --dir "$HOME" "placeholder" 2>/dev/null
        tail -10 ~/.bash_history | while IFS= read -r cmd; do
            [ -n "$cmd" ] && HISTFILE=/tmp/empty_history mcfly add --exit 0 --dir "$HOME" "$cmd" 2>/dev/null || true
        done
        rm -f /tmp/empty_history
        echo "✓ Test database created ($(entry_count) entries)"
        continue
    }

    [[ "$choice" =~ ^[cC]$ ]] && {
        echo -n "⚠️  Delete all McFly history? (y/N): "
        read -r confirm
        [[ "$confirm" =~ ^[yY]$ ]] && {
            [ -f "$MCFLY_DB" ] && cp "$MCFLY_DB" "$MCFLY_DB.backup.$(date +%Y%m%d_%H%M%S)"
            rm -f "$MCFLY_DB" && echo "✓ Database cleaned"
        } || echo "Cancelled"
        continue
    }

    # Import selection
    if [ -z "$choice" ]; then
        for m in "${MACHINES[@]}"; do
            [ "$m" = "$CURRENT_MACHINE" ] && { import "$m"; break; }
        done
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#MACHINES[@]}" ]; then
        import "${MACHINES[$((choice - 1))]}"
    else
        echo "Invalid choice"
    fi
    echo ""
done
