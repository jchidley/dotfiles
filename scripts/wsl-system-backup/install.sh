#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
sudo install -o root -g root -m 755 "$SCRIPT_DIR/validate-wsl-system-restore" \
  /usr/local/sbin/validate-wsl-system-restore
printf 'Installed the non-destructive whole-system restore validator.\n'
