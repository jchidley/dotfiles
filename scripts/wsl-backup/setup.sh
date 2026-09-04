#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DISTRO_NAME=${WSL_DISTRO_NAME:-Debian-Recovered}
WINDOWS_INTEGRATION=1
DESTDIR=${WSL_BACKUP_DESTDIR:-${DESTDIR:-}}
POWERSHELL=${WSL_BACKUP_POWERSHELL:-pwsh.exe}
WSLPATH=${WSL_BACKUP_WSLPATH:-wslpath}

usage() {
  cat <<'EOF'
Usage: ./scripts/wsl-backup/setup.sh [--distro NAME] [--no-windows-integration]

Install or update the WSL backup tools. Existing repositories, credentials,
snapshots, archives, and manifests are not created, replaced, or removed.
Routine home-backup scheduling belongs to Linux systemd. Setup installs the
scheduler and units but never enables the timer; cutover is a separate reviewed
migration action. Windows integration installs only the whole-system export
controller and never registers routine Windows tasks.
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
    --no-windows-integration|--no-windows-tasks) WINDOWS_INTEGRATION=0; shift ;;
    --force-windows-tasks) echo '--force-windows-tasks is retired: routine scheduling is Linux-owned' >&2; exit 2 ;;
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

if ((WINDOWS_INTEGRATION)); then
  require_command "$POWERSHELL" "$POWERSHELL is unavailable; Linux tools were installed but Windows integration was skipped"
  require_command "$WSLPATH" "$WSLPATH is unavailable; Linux tools were installed but Windows integration was skipped"

  installer=$("$WSLPATH" -w "$SCRIPT_DIR/Install-Windows.ps1")
  "$POWERSHELL" -NoLogo -NoProfile -NonInteractive -File "$installer" -DistroName "$DISTRO_NAME" </dev/null

  # PowerShell, not Bash, expands $env:LOCALAPPDATA in this single-quoted argument.
  # shellcheck disable=SC2016
  windows_system_script=$("$POWERSHELL" -NoLogo -NoProfile -NonInteractive -Command \
    '[Console]::Write((Join-Path $env:LOCALAPPDATA "WSLBackup\system\Backup-WslSystem.ps1"))' </dev/null | tr -d '\r')
  [[ -n "$windows_system_script" ]] || { echo "Could not resolve installed Windows controller" >&2; exit 1; }
  if [[ -n "$DESTDIR" ]]; then
    printf '%s\n' "$windows_system_script" > "$DESTDIR/etc/wsl-backup/windows-system-script"
  else
    printf '%s\n' "$windows_system_script" | sudo tee /etc/wsl-backup/windows-system-script >/dev/null
    sudo chmod 644 /etc/wsl-backup/windows-system-script
  fi
fi

cat >&2 <<'EOF'
The Linux systemd timer was installed but not enabled. Use the reviewed
migration tool after preserving and validating the deployed legacy tasks.
EOF

cat <<EOF
WSL backup tools installed for distro: $DISTRO_NAME
Run: wsl-backup status
Reference: scripts/wsl-backup/README.md
EOF
