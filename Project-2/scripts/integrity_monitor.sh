#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE="$BASE_DIR/reports/config_baseline.sha256"
MONITORED="$BASE_DIR/config/monitored_files.conf"
LOG="$BASE_DIR/logs/automation.log"

echo "[INFO] Integrity monitor started" >> "$LOG"

if [ ! -f "$BASELINE" ]; then
    echo "[ERROR] Baseline file not found!" >> "$LOG"
    exit 1
fi

TMP_FILE=$(mktemp)

while read -r file; do
    if [ -f "$file" ]; then
        sha256sum "$file" >> "$TMP_FILE"
    else
        echo "[WARN] Missing file: $file" >> "$LOG"
    fi
done < "$MONITORED"

if diff "$BASELINE" "$TMP_FILE" > /dev/null; then
    echo "[INFO] No integrity changes detected" >> "$LOG"
else
    echo "[ALERT] Integrity violation detected!" >> "$LOG"
    bash "$BASE_DIR/scripts/incident_response.sh"
fi

rm "$TMP_FILE"
echo "[INFO] Integrity monitor finished" >> "$LOG"

