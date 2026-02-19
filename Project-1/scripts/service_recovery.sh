#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$BASE_DIR/logs/linux-monitor.log"
TAG="linux-monitor"

mkdir -p "$BASE_DIR/logs"
touch "$LOG"

log() {
  local lvl="$1"; shift
  local msg="$*"
  local line="[$(date '+%F %T')] [$lvl] $msg"
  echo "$line" >> "$LOG"
  logger -t "$TAG" "$line" 2>/dev/null || true
}

# Map "logical name" -> actual systemd service name on Ubuntu
SERVICES=("ssh" "cron" "nginx")

for svc in "${SERVICES[@]}"; do
  # If systemd doesn't know this service at all
if ! systemctl status "$svc" >/dev/null 2>&1; then
  log WARN "Service ${svc} not found on this system"
  continue
fi


  if systemctl is-active --quiet "$svc"; then
    log INFO "Service ${svc} is active"
  else
    log WARN "Service ${svc} is inactive. Attempting restart..."
    systemctl restart "$svc" || true

    if systemctl is-active --quiet "$svc"; then
      log INFO "Service ${svc} restarted successfully"
    else
      log ERROR "Service ${svc} FAILED to restart"
    fi
  fi
done
