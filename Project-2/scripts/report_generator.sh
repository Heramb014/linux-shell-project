#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$BASE_DIR/logs/automation.log"
REPORT="$BASE_DIR/reports/daily_report.txt"

echo "===== Daily System Report =====" > "$REPORT"
echo "Generated on: $(date)" >> "$REPORT"
echo "" >> "$REPORT"

echo "---- Backup Activity ----" >> "$REPORT"
grep "Backup created" "$LOG" >> "$REPORT" || echo "No backup activity" >> "$REPORT"

echo "" >> "$REPORT"
echo "---- Config Drift ----" >> "$REPORT"
grep "Config drift" "$LOG" >> "$REPORT" || echo "No config drift events" >> "$REPORT"

echo "" >> "$REPORT"
echo "---- Integrity Monitoring ----" >> "$REPORT"
grep "Integrity" "$LOG" >> "$REPORT" || echo "No integrity events" >> "$REPORT"

echo "" >> "$REPORT"
echo "---- Incident Response ----" >> "$REPORT"
grep "Incident response" "$LOG" >> "$REPORT" || echo "No incident response events" >> "$REPORT"

echo "" >> "$REPORT"
echo "---- Restore Validation ----" >> "$REPORT"
grep "Restore validation" "$LOG" >> "$REPORT" || echo "No restore validation events" >> "$REPORT"

echo "[INFO] Daily report generated" >> "$LOG"
