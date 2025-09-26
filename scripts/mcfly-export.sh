#!/bin/bash
# Export and encrypt McFly database for chezmoi

set -e

MCFLY_DB="$HOME/.local/share/mcfly/history.db"
CHEZMOI_DIR="$HOME/.local/share/chezmoi"

# Machine identifier - unique per WSL instance
MACHINE_TAG="$(hostname)_$(cat /etc/machine-id 2>/dev/null | head -c 8 || echo "unknown")"
EXPORT_FILE="$CHEZMOI_DIR/mcfly_backups/encrypted_mcfly_${MACHINE_TAG}.db.gpg"

echo "Machine: $MACHINE_TAG"

# Check if database exists
[ ! -f "$MCFLY_DB" ] && { echo "McFly database not found at $MCFLY_DB"; exit 1; }

# Create directory
mkdir -p "$(dirname "$EXPORT_FILE")"

# Get password
echo "Getting password from Bitwarden (bashrc-pgp)..."
PASSWORD=$(bw get password "bashrc-pgp" 2>/dev/null || echo "")

if [ -z "$PASSWORD" ]; then
    echo "Enter encryption password:"
    read -s PASSWORD
    echo
fi

# Encrypt
echo "Encrypting..."
gpg --batch --yes --passphrase "$PASSWORD" \
    --cipher-algo AES256 --symmetric --armor \
    --output "$EXPORT_FILE" "$MCFLY_DB"

echo "✓ Encrypted: $(basename "$EXPORT_FILE")"
echo "  Commit this file to your repository"