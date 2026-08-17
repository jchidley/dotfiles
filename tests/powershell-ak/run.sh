#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) test_script=$(cygpath -w "$script_dir/test-ak-profile.ps1") ;;
  *) test_script=$(wslpath -w "$script_dir/test-ak-profile.ps1") ;;
esac
MSYS_NO_PATHCONV=1 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$test_script"
