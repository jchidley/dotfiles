#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DISTRO_NAME=${WSL_DISTRO_NAME:-Debian-Recovered}
REGISTER_TASKS=1
FORCE_TASKS=0
DESTDIR=${WSL_BACKUP_DESTDIR:-${DESTDIR:-}}
POWERSHELL=${WSL_BACKUP_POWERSHELL:-powershell.exe}
WSLPATH=${WSL_BACKUP_WSLPATH:-wslpath}

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

require_command() {
  local command_name=$1 message=$2
  if [[ "$command_name" == */* ]]; then
    [[ -x "$command_name" ]] || { echo "$message" >&2; exit 1; }
  else
    command -v "$command_name" >/dev/null 2>&1 || { echo "$message" >&2; exit 1; }
  fi
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

if [[ -n "$DESTDIR" ]]; then
  privilege=()
  ownership=()
else
  require_command sudo "sudo is required"
  privilege=(sudo)
  ownership=(-o root -g root)
fi

DESTDIR=$DESTDIR "$SCRIPT_DIR/home/install.sh"
DESTDIR=$DESTDIR "$SCRIPT_DIR/system/install.sh"
"${privilege[@]}" install -d "${ownership[@]}" -m 755 "$DESTDIR/etc/wsl-backup" "$DESTDIR/usr/local/bin"
"${privilege[@]}" install "${ownership[@]}" -m 755 "$SCRIPT_DIR/wsl-backup" "$DESTDIR/usr/local/bin/wsl-backup"

if ((REGISTER_TASKS)); then
  require_command "$POWERSHELL" "$POWERSHELL is unavailable; Linux tools were installed but Windows integration was skipped"
  require_command "$WSLPATH" "$WSLPATH is unavailable; Linux tools were installed but Windows integration was skipped"

  installer=$("$WSLPATH" -w "$SCRIPT_DIR/Install-Windows.ps1")
  "$POWERSHELL" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$installer" -DistroName "$DISTRO_NAME" </dev/null

  # PowerShell, not Bash, expands $env:LOCALAPPDATA in this single-quoted argument.
  # shellcheck disable=SC2016
  windows_system_script=$("$POWERSHELL" -NoProfile -NonInteractive -Command \
    '[Console]::Write((Join-Path $env:LOCALAPPDATA "WSLBackup\system\Backup-WslSystem.ps1"))' </dev/null | tr -d '\r')
  [[ -n "$windows_system_script" ]] || { echo "Could not resolve installed Windows controller" >&2; exit 1; }
  if [[ -n "$DESTDIR" ]]; then
    printf '%s\n' "$windows_system_script" > "$DESTDIR/etc/wsl-backup/windows-system-script"
  else
    printf '%s\n' "$windows_system_script" | sudo tee /etc/wsl-backup/windows-system-script >/dev/null
    sudo chmod 644 /etc/wsl-backup/windows-system-script
  fi

  if "${privilege[@]}" test -s "$DESTDIR/etc/restic/home.password" && \
      "${privilege[@]}" test -f "$DESTDIR/var/lib/restic/home/config"; then
    tasks=$("$WSLPATH" -w "$SCRIPT_DIR/home/Register-WindowsTasks.ps1")
    task_args=(-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$tasks" -DistroName "$DISTRO_NAME")
    if ((FORCE_TASKS)); then
      task_args+=(-Force)
    fi
    "$POWERSHELL" "${task_args[@]}" </dev/null
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
