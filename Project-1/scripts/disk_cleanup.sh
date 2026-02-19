#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$BASE_DIR/logs/linux-monitor.log"
TAG="linux-monitor"

# how old before deleting (safe defaults)
TMP_DAYS=7
LOG_DAYS=14
JOURNAL_DAYS=14

mkdir -p "$BASE_DIR/logs"
touch "$LOG"

log() {
  local lvl="$1"; shift
  local msg="$*"
  local line="[$(date '+%F %T')] [$lvl] $msg"
  echo "$line" >> "$LOG"
  logger -t "$TAG" "$line" 2>/dev/null || true
}

free_bytes_root() {
  df -B1 / | awk 'NR==2 {print $4}'
}

before="$(free_bytes_root)"
log INFO "Disk cleanup started. Free bytes before: $before"

# 1) temp files
log INFO "Deleting /tmp files older than ${TMP_DAYS} days"
find /tmp -xdev -type f -mtime +"$TMP_DAYS" -print -delete 2>/dev/null || true

log INFO "Deleting /var/tmp files older than ${TMP_DAYS} days"
find /var/tmp -xdev -type f -mtime +"$TMP_DAYS" -print -delete 2>/dev/null || true

# 2) rotated / compressed logs
log INFO "Deleting rotated logs in /var/log older than ${LOG_DAYS} days"
find /var/log -type f \
  \( -name "*.gz" -o -name "*.old" -o -regex '.*\.[0-9]+(\.gz)?$' \) \
  -mtime +"$LOG_DAYS" -print -delete 2>/dev/null || true

# 3) systemd journal vacuum (if available)
if command -v journalctl >/dev/null 2>&1; then
  log INFO "Vacuuming journal older than ${JOURNAL_DAYS} days"
  journalctl --vacuum-time="${JOURNAL_DAYS}d" >/dev/null 2>&1 || true
else
  log WARN "journalctl not found; skipping journal vacuum"
fi

after="$(free_bytes_root)"
reclaimed=$((after - before))

log INFO "Disk cleanup finished. Free bytes after: $after"
log INFO "Space reclaimed: $reclaimed bytes"

echo "Cleanup complete"
echo "Free before: $before bytes"
echo "Free after : $after bytes"
echo "Reclaimed  : $reclaimed bytes"
