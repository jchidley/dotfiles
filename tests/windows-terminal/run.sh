#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_script=$(wslpath -w "$repo_dir/tests/windows-terminal/test-configure-windows-terminal.ps1")
command -v pwsh.exe >/dev/null 2>&1 || { echo "PowerShell 7 (pwsh.exe) is required" >&2; exit 1; }
pwsh.exe -NoLogo -NoProfile -File "$test_script"
