#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$BASE_DIR/logs/automation.log"
REPORT="$BASE_DIR/reports/daily_report.txt"

log() {
    echo "[$(date)] $1" >> "$LOG"
}

log "Incident response started"

# Check if integrity baseline exists
if [ ! -f "$BASE_DIR/reports/config_baseline.sha256" ]; then
    log "[ALERT] Baseline missing! Possible tampering."
    echo "Baseline missing!" >> "$REPORT"
else
    log "Baseline file exists"
fi

# Example response: check for suspicious files
SUSPICIOUS=$(find /tmp -type f -name "*.sh" 2>/dev/null | wc -l)

if [ "$SUSPICIOUS" -gt 5 ]; then
    log "[ALERT] Suspicious number of shell scripts found in /tmp"
    echo "Suspicious activity detected in /tmp" >> "$REPORT"
else
    log "No suspicious activity detected"
fi

log "Incident response finished"
