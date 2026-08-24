#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) test_script=$(cygpath -w "$script_dir/test-ak-profile.ps1") ;;
  *) test_script=$(wslpath -w "$script_dir/test-ak-profile.ps1") ;;
esac
command -v pwsh.exe >/dev/null 2>&1 || { echo "PowerShell 7 (pwsh.exe) is required" >&2; exit 1; }
MSYS_NO_PATHCONV=1 pwsh.exe -NoLogo -NoProfile -File "$test_script"
