#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_FILE="$BASE_DIR/config/monitored_files.conf"
LOG_FILE="$BASE_DIR/logs/automation.log"
STATE_DIR="$BASE_DIR/reports"
BASELINE="$STATE_DIR/config_baseline.sha256"
CURRENT="$STATE_DIR/config_current.sha256"
TAG="linux-monitor"

mkdir -p "$BASE_DIR/logs" "$STATE_DIR"
touch "$LOG_FILE"

log() {
  local lvl="$1"; shift
  local msg="$*"
  local line="[$(date '+%F %T')] [$lvl] $msg"
  echo "$line" >> "$LOG_FILE"
  logger -t "$TAG" "$line" 2>/dev/null || true
}

if [[ ! -f "$CONF_FILE" ]]; then
  log "ERROR" "Missing $CONF_FILE. Create it with files to monitor."
  echo "ERROR: Missing $CONF_FILE"
  exit 1
fi

# Read files (ignore blank lines + comments)
mapfile -t FILES < <(grep -vE '^\s*#' "$CONF_FILE" | sed '/^\s*$/d')

if [[ ${#FILES[@]} -eq 0 ]]; then
  log "ERROR" "No files listed in $CONF_FILE"
  echo "ERROR: No files listed in $CONF_FILE"
  exit 1
fi

log "INFO" "Config drift check started"

# Create current hash list (only for files that exist)
: > "$CURRENT"
missing=0

for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    sha256sum "$f" >> "$CURRENT"
  else
    log "WARN" "File not found: $f"
    ((missing++)) || true
  fi
done

# First run: create baseline
if [[ ! -f "$BASELINE" ]]; then
  cp "$CURRENT" "$BASELINE"
  log "INFO" "Baseline created at $BASELINE (missing files: $missing)"
  echo "Baseline created ✅"
  exit 0
fi

# Compare baseline vs current
if diff -q "$BASELINE" "$CURRENT" >/dev/null; then
  log "INFO" "No config drift detected (missing files: $missing)"
  echo "No config drift ✅"
else
  log "WARN" "CONFIG DRIFT DETECTED! Differences found."
  echo "CONFIG DRIFT DETECTED ❌"
  echo "Diff:"
  diff "$BASELINE" "$CURRENT" || true
fi

log "INFO" "Config drift check finished"
