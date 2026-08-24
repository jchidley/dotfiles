#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DESTDIR=${DESTDIR:-}

command -v restic >/dev/null 2>&1 || {
  echo "restic is not installed" >&2
  exit 1
}
command -v sqlite3 >/dev/null 2>&1 || {
  echo "sqlite3 is not installed" >&2
  exit 1
}

if [[ -n "$DESTDIR" ]]; then
  privilege=()
  ownership=()
else
  privilege=(sudo)
  ownership=(-o root -g root)
fi

"${privilege[@]}" install -d -m 755 "$DESTDIR/etc/restic" "$DESTDIR/usr/local/sbin"
"${privilege[@]}" install -d -m 700 \
  "$DESTDIR/var/lib/restic" "$DESTDIR/var/lib/restic/staging" \
  "$DESTDIR/var/cache/restic-home" "$DESTDIR/var/log/restic-home"
"${privilege[@]}" install "${ownership[@]}" -m 755 "$SCRIPT_DIR/backup-wsl-home" \
  "$DESTDIR/usr/local/sbin/backup-wsl-home"
"${privilege[@]}" install "${ownership[@]}" -m 644 "$SCRIPT_DIR/home.conf" \
  "$DESTDIR/etc/restic/home.conf"

cat <<'EOF'
Installed the local Restic home-backup program and non-secret configuration.
The installer deliberately does not create credentials, initialize a repository,
or register Windows tasks. See scripts/wsl-backup/README.md.
EOF
