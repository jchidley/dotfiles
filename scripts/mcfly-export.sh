#!/bin/bash
# Export and encrypt McFly database for chezmoi

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
        echo "Enter encryption password:"
        read -r -s pw
        echo
    fi

    echo "$pw"
}

MCFLY_DB="$HOME/.local/share/mcfly/history.db"
CHEZMOI_DIR="$(get_chezmoi_dir)"

# Machine identifier - unique per instance
MACHINE_TAG="$(hostname)_$(cat /etc/machine-id 2>/dev/null | head -c 8 || echo "unknown")"
EXPORT_FILE="$CHEZMOI_DIR/mcfly_backups/encrypted_mcfly_${MACHINE_TAG}.db.gpg"

echo "Machine: $MACHINE_TAG"

command -v gpg >/dev/null 2>&1 || { echo "gpg is required"; exit 1; }

# Check if database exists
[ ! -f "$MCFLY_DB" ] && { echo "McFly database not found at $MCFLY_DB"; exit 1; }

# Create directory
mkdir -p "$(dirname "$EXPORT_FILE")"

# Get password
echo "Getting password from Bitwarden (bashrc-pgp)..."
PASSWORD="$(get_password)"

# Encrypt
echo "Encrypting..."
gpg --batch --yes --passphrase "$PASSWORD" \
    --cipher-algo AES256 --symmetric --armor \
    --output "$EXPORT_FILE" "$MCFLY_DB"

echo "✓ Encrypted: $(basename "$EXPORT_FILE")"
echo "  Commit this file to your repository"
