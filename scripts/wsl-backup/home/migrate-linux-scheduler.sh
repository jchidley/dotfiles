#!/usr/bin/env bash
set -euo pipefail

ACTION=${1:-}
SOURCE_DIR=${2:-}
SERVICE=wsl-home-scheduler.service
TIMER=wsl-home-scheduler.timer

[[ -n $ACTION ]] || { echo 'usage: migrate-linux-scheduler.sh ACTION [SOURCE_DIR]' >&2; exit 2; }

require_running_systemd() {
  [[ $(systemctl is-system-running 2>/dev/null || true) =~ ^(running|degraded)$ ]] || {
    echo 'systemd is not active' >&2
    exit 1
  }
}

verify_no_windows_boundary() {
  if grep -Eiq 'wsl\.exe|pwsh|powershell|scheduledtask' \
      /usr/local/sbin/wsl-home-scheduler \
      /etc/systemd/system/$SERVICE \
      /etc/systemd/system/$TIMER; then
    echo 'installed Linux scheduler contains a Windows execution boundary' >&2
    exit 1
  fi
}

verify_installed() {
  [[ -n $SOURCE_DIR && -d $SOURCE_DIR ]] || { echo 'reviewed source directory is required' >&2; exit 2; }
  local pairs=(
    "$SOURCE_DIR/wsl-home-scheduler:/usr/local/sbin/wsl-home-scheduler"
    "$SOURCE_DIR/systemd/$SERVICE:/etc/systemd/system/$SERVICE"
    "$SOURCE_DIR/systemd/$TIMER:/etc/systemd/system/$TIMER"
  ) pair source installed
  for pair in "${pairs[@]}"; do
    source=${pair%%:*}
    installed=${pair#*:}
    [[ -f $source && -f $installed ]] || { echo "missing source or installed file: $pair" >&2; exit 1; }
    [[ $(sha256sum "$source" | awk '{print $1}') == $(sha256sum "$installed" | awk '{print $1}') ]] || {
      echo "installed file differs from reviewed source: $installed" >&2
      exit 1
    }
  done
  systemd-analyze verify "/etc/systemd/system/$SERVICE" "/etc/systemd/system/$TIMER"
  verify_no_windows_boundary
}

case $ACTION in
  install-or-verify)
    require_running_systemd
    [[ -n $SOURCE_DIR && -d $SOURCE_DIR ]] || { echo 'reviewed source directory is required' >&2; exit 2; }
    sudo install -o root -g root -m 755 "$SOURCE_DIR/wsl-home-scheduler" /usr/local/sbin/wsl-home-scheduler
    sudo install -o root -g root -m 644 "$SOURCE_DIR/systemd/$SERVICE" "$SOURCE_DIR/systemd/$TIMER" /etc/systemd/system/
    sudo systemctl daemon-reload
    if systemctl is-enabled --quiet "$TIMER"; then
      echo 'Linux timer was already enabled before cutover' >&2
      exit 1
    fi
    verify_installed
    sudo systemctl start "$SERVICE"
    systemctl is-failed --quiet "$SERVICE" && { echo 'manual coordinator verification failed' >&2; exit 1; }
    sudo /usr/local/sbin/backup-wsl-home status
    printf 'LINUX_PREFLIGHT_OK timer=disabled service=verified manual_coordinator=successful\n'
    ;;
  verify-disabled)
    require_running_systemd
    verify_installed
    ! systemctl is-enabled --quiet "$TIMER" || { echo 'Linux timer is unexpectedly enabled' >&2; exit 1; }
    printf 'LINUX_TIMER_DISABLED verified=yes\n'
    ;;
  enable)
    require_running_systemd
    verify_installed
    sudo systemctl enable --now "$TIMER"
    systemctl is-enabled --quiet "$TIMER"
    systemctl is-active --quiet "$TIMER"
    systemctl list-timers "$TIMER" --no-pager
    printf 'LINUX_TIMER_ENABLED verified=yes\n'
    ;;
  disable)
    require_running_systemd
    sudo systemctl disable --now "$TIMER"
    ! systemctl is-enabled --quiet "$TIMER"
    printf 'LINUX_TIMER_DISABLED verified=yes\n'
    ;;
  status)
    require_running_systemd
    verify_installed
    systemctl is-enabled "$TIMER" || true
    systemctl is-active "$TIMER" || true
    systemctl status "$SERVICE" "$TIMER" --no-pager || true
    systemctl list-timers "$TIMER" --no-pager || true
    ;;
  *) echo "unknown migration Linux action: $ACTION" >&2; exit 2 ;;
esac
