#!/usr/bin/env bash

echo "===== System Health Check ====="
echo ""
echo "CPU Usage:"
top -bn1 | grep "Cpu"

echo ""
echo "Memory Usage:"
free -h

echo ""
echo "Disk Usage:"
df -h
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$BASE_DIR/config/thresholds.conf"
LOG="$BASE_DIR/logs/linux-monitor.log"
TAG="linux-monitor"

mkdir -p "$BASE_DIR/logs"
touch "$LOG"

source "$CONFIG"

log() {
  local lvl="$1"; shift
  local msg="$*"
  local line="[$(date '+%F %T')] [$lvl] $msg"
  echo "$line" >> "$LOG"
  logger -t "$TAG" "$line" 2>/dev/null || true
}

cpu_usage() {
  top -bn1 | awk -F',' '/Cpu\(s\)/ {for(i=1;i<=NF;i++) if($i~/%id/) {gsub(/[^0-9.]/,"",$i); print 100-$i}}'
}

mem_usage() {
  free | awk '/Mem:/ {printf "%.1f", $3/$2*100}'
}

disk_usage() {
  df / | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

load_avg() {
  uptime | awk -F'load average: ' '{print $2}' | cut -d',' -f1
}

zombies() {
  ps -eo stat | awk '$1 ~ /^Z/ {c++} END {print c+0}'
}

cpu=$(cpu_usage)
mem=$(mem_usage)
disk=$(disk_usage)
load=$(load_avg)
zomb=$(zombies)

log INFO "CPU=${cpu}% MEM=${mem}% DISK(/)=${disk}% LOAD1=${load} ZOMBIES=${zomb}"

# ---- Threshold checks (safe version) ----

if awk -v c="$cpu" -v t="$CPU_WARN" 'BEGIN{exit !(c>t)}'; then
  log WARN "High CPU usage"
fi

if awk -v m="$mem" -v t="$MEM_WARN" 'BEGIN{exit !(m>t)}'; then
  log WARN "High Memory usage"
fi

if [ "$disk" -gt "$DISK_WARN" ]; then
  log WARN "High Disk usage"
fi

if awk -v l="$load" -v t="$LOAD1_WARN" 'BEGIN{exit !(l>t)}'; then
  log WARN "High Load Average"
fi

if [ "$zomb" -gt "$ZOMBIE_WARN" ]; then
  log WARN "Zombie processes detected"
fi
