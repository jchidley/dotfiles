#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

command -v restic >/dev/null 2>&1 || {
  echo "restic is not installed" >&2
  exit 1
}
command -v sqlite3 >/dev/null 2>&1 || {
  echo "sqlite3 is not installed" >&2
  exit 1
}

sudo install -d -m 755 /etc/restic
sudo install -d -m 700 /var/lib/restic /var/lib/restic/staging /var/cache/restic-home /var/log/restic-home
sudo install -o root -g root -m 755 "$SCRIPT_DIR/backup-wsl-home" /usr/local/sbin/backup-wsl-home
sudo install -o root -g root -m 644 "$SCRIPT_DIR/home.conf" /etc/restic/home.conf

cat <<'EOF'
Installed the local Restic home-backup program and non-secret configuration.
The installer deliberately does not create credentials, initialize a repository,
or register Windows tasks. See scripts/wsl-backup/README.md.
EOF
