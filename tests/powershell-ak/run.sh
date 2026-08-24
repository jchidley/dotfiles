#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "$script_dir/../.." && pwd)
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    repo_path=$(cygpath -w "$repo_dir")
    test_path=$(cygpath -w "$script_dir")
    ;;
  *)
    repo_path=$(wslpath -w "$repo_dir")
    test_path=$(wslpath -w "$script_dir")
    ;;
esac
command -v pwsh.exe >/dev/null 2>&1 || { echo "PowerShell 7 (pwsh.exe) is required" >&2; exit 1; }
# Use stdin under RemoteSigned; provide paths because stdin has no PSScriptRoot.
WSLENV="${WSLENV:+$WSLENV:}DOTFILES_REPO_ROOT:DOTFILES_TEST_DIR" \
DOTFILES_REPO_ROOT="$repo_path" DOTFILES_TEST_DIR="$test_path" \
MSYS_NO_PATHCONV=1 pwsh.exe -NoLogo -NoProfile -NonInteractive -Command - \
  < "$script_dir/test-ak-profile.ps1"
