#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DESTDIR=${DESTDIR:-}
if [[ -n "$DESTDIR" ]]; then
  privilege=()
  ownership=()
else
  privilege=(sudo)
  ownership=(-o root -g root)
fi
"${privilege[@]}" install -d -m 755 "$DESTDIR/usr/local/sbin"
"${privilege[@]}" install "${ownership[@]}" -m 755 "$SCRIPT_DIR/validate-wsl-system-restore" \
  "$DESTDIR/usr/local/sbin/validate-wsl-system-restore"
printf 'Installed the non-destructive whole-system restore validator.\n'
