#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_dir="$repo_dir/tests/windows-terminal"
command -v pwsh.exe >/dev/null 2>&1 || { echo "PowerShell 7 (pwsh.exe) is required" >&2; exit 1; }
# Feed trusted test content over stdin so RemoteSigned does not reject its WSL
# UNC path. Explicit Windows paths replace PSScriptRoot, which stdin lacks.
WSLENV="${WSLENV:+$WSLENV:}DOTFILES_REPO_ROOT:DOTFILES_TEST_DIR" \
DOTFILES_REPO_ROOT=$(wslpath -w "$repo_dir") \
DOTFILES_TEST_DIR=$(wslpath -w "$test_dir") \
pwsh.exe -NoLogo -NoProfile -NonInteractive -Command - \
  < "$test_dir/test-configure-windows-terminal.ps1"
