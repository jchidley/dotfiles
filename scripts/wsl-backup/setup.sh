#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DISTRO_NAME=${WSL_DISTRO_NAME:-Debian-Recovered}
REGISTER_TASKS=1
FORCE_TASKS=0

usage() {
  cat <<'EOF'
Usage: ./scripts/wsl-backup/setup.sh [--distro NAME] [--no-windows-tasks]
                                      [--force-windows-tasks]

Install or update the WSL backup tools. Existing repositories, credentials,
snapshots, archives, and manifests are not created, replaced, or removed.
Windows tasks are registered only when the local Restic repository already
has both its config and password file. Existing task schedules are preserved
unless --force-windows-tasks is supplied.
EOF
}

while (($#)); do
  case "$1" in
    --distro)
      (($# >= 2)) || { echo "--distro requires a value" >&2; exit 2; }
      DISTRO_NAME=$2
      shift 2
      ;;
    --no-windows-tasks) REGISTER_TASKS=0; shift ;;
    --force-windows-tasks) FORCE_TASKS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$DISTRO_NAME" && "$DISTRO_NAME" != *$'\n'* && "$DISTRO_NAME" != *$'\r'* && "$DISTRO_NAME" != *'"'* ]] || {
  echo "Invalid WSL distro name" >&2
  exit 2
}
command -v sudo >/dev/null 2>&1 || { echo "sudo is required" >&2; exit 1; }

"$SCRIPT_DIR/home/install.sh"
"$SCRIPT_DIR/system/install.sh"
sudo install -d -o root -g root -m 755 /etc/wsl-backup
sudo install -o root -g root -m 755 "$SCRIPT_DIR/wsl-backup" /usr/local/bin/wsl-backup

if ((REGISTER_TASKS)); then
  command -v powershell.exe >/dev/null 2>&1 || {
    echo "powershell.exe is unavailable; Linux tools were installed but Windows integration was skipped" >&2
    exit 1
  }
  command -v wslpath >/dev/null 2>&1 || {
    echo "wslpath is unavailable; Linux tools were installed but Windows integration was skipped" >&2
    exit 1
  }

  installer=$(wslpath -w "$SCRIPT_DIR/Install-Windows.ps1")
  powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$installer" -DistroName "$DISTRO_NAME"

  # PowerShell, not Bash, expands $env:LOCALAPPDATA in this single-quoted argument.
  # shellcheck disable=SC2016
  windows_system_script=$(powershell.exe -NoProfile -NonInteractive -Command \
    '[Console]::Write((Join-Path $env:LOCALAPPDATA "WSLBackup\system\Backup-WslSystem.ps1"))' | tr -d '\r')
  [[ -n "$windows_system_script" ]] || { echo "Could not resolve installed Windows controller" >&2; exit 1; }
  printf '%s\n' "$windows_system_script" | sudo tee /etc/wsl-backup/windows-system-script >/dev/null
  sudo chmod 644 /etc/wsl-backup/windows-system-script

  if sudo test -s /etc/restic/home.password && sudo test -f /var/lib/restic/home/config; then
    tasks=$(wslpath -w "$SCRIPT_DIR/home/Register-WindowsTasks.ps1")
    task_args=(-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$tasks" -DistroName "$DISTRO_NAME")
    if ((FORCE_TASKS)); then
      task_args+=(-Force)
    fi
    powershell.exe "${task_args[@]}"
  else
    cat >&2 <<'EOF'
Local Restic credentials or repository config are absent, so scheduled tasks
were not registered. Follow scripts/wsl-backup/home/README.md, then rerun setup.
EOF
  fi
fi

cat <<EOF
WSL backup tools installed for distro: $DISTRO_NAME
Run: wsl-backup status
Reference: scripts/wsl-backup/README.md
EOF
