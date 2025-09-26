#!/bin/bash
# Import McFly history from encrypted backups

set -e

MCFLY_DB="$HOME/.local/share/mcfly/history.db"
ENCRYPTED_DIR="$HOME/.local/share/chezmoi/mcfly_backups"
CURRENT_MACHINE="$(hostname)_$(cat /etc/machine-id 2>/dev/null | head -c 8 || echo "unknown")"

command -v mcfly &>/dev/null || { echo "McFly not installed"; exit 1; }

import() {
    local FILE="$ENCRYPTED_DIR/encrypted_mcfly_${1}.db.gpg"
    [ ! -f "$FILE" ] && { echo "✗ File not found: $FILE"; return 1; }

    PASSWORD=$(bw get password "bashrc-pgp" 2>/dev/null || { read -s -p "Password: " PASSWORD; echo; echo "$PASSWORD"; })

    # Fast path: empty database
    ENTRY_COUNT=$([ -f "$MCFLY_DB" ] && mcfly dump --format json 2>/dev/null | jq '. | length' 2>/dev/null || echo 0)
    if [ "$ENTRY_COUNT" -eq 0 ]; then
        mkdir -p "$(dirname "$MCFLY_DB")"
        gpg --batch --yes --passphrase "$PASSWORD" --decrypt "$FILE" > "$MCFLY_DB" 2>/dev/null &&
        echo "✓ Imported from $1 (fast)" && return 0 || { echo "✗ Decrypt failed"; return 1; }
    fi

    # Merge path: SQLite direct merge
    local TEMP_DB="/tmp/mcfly_$(date +%s).db"
    cp "$MCFLY_DB" "$MCFLY_DB.backup.$(date +%Y%m%d_%H%M%S)"

    if gpg --batch --yes --passphrase "$PASSWORD" --decrypt "$FILE" > "$TEMP_DB" 2>/dev/null; then
        BEFORE=$(mcfly stats | grep contains | awk '{print $6}')
        echo "Merging from $1 (before: $BEFORE items)..."

        sqlite3 "$MCFLY_DB" "
        ATTACH '$TEMP_DB' AS src;
        INSERT OR IGNORE INTO commands (cmd, cmd_tpl, session_id, when_run, exit_code, selected, dir, old_dir)
        SELECT cmd, cmd_tpl, session_id, when_run, exit_code, selected, dir, old_dir FROM src.commands
        WHERE NOT EXISTS (SELECT 1 FROM commands WHERE commands.cmd = src.commands.cmd
                         AND commands.dir = src.commands.dir AND commands.when_run = src.commands.when_run);
        DETACH src;"

        AFTER=$(mcfly stats | grep contains | awk '{print $6}')
        echo "✓ Added $((AFTER - BEFORE)) entries from $1"
        rm -f "$TEMP_DB"
    else
        echo "✗ Decrypt failed"; return 1
    fi
}

# Get available exports
MACHINES=($(ls "$ENCRYPTED_DIR"/encrypted_mcfly_*.db.gpg 2>/dev/null | sed 's/.*encrypted_mcfly_//; s/.db.gpg//' | sort))
[ ${#MACHINES[@]} -eq 0 ] && { echo "No exports found"; exit 0; }

echo "McFly Import (current: $CURRENT_MACHINE)"
echo ""

while true; do
    for i in "${!MACHINES[@]}"; do
        [ "${MACHINES[$i]}" = "$CURRENT_MACHINE" ] && def=" (default)" || def=""
        echo "$((i+1))) ${MACHINES[$i]}$def"
    done
    echo "c) Clean/Reset database"
    echo "t) Create test database"
    echo "q) Quit"
    read -p "> " choice

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
        echo "✓ Test database created ($(mcfly stats | grep contains | awk '{print $6}') entries)"
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
        import "${MACHINES[$((choice-1))]}"
    else
        echo "Invalid choice"
    fi
    echo ""
done