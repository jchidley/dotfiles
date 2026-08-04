#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_script=$(wslpath -w "$repo_dir/tests/windows-terminal/test-configure-windows-terminal.ps1")
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$test_script"
