#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$BASE_DIR/backups"
LOG="$BASE_DIR/logs/automation.log"

echo "[INFO] Restore validation started" >> "$LOG"

LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n 1 || true)

if [ -z "$LATEST_BACKUP" ]; then
    echo "[ERROR] No backup files found!" >> "$LOG"
    exit 1
fi

TMP_RESTORE=$(mktemp -d)

if tar -xzf "$LATEST_BACKUP" -C "$TMP_RESTORE"; then
    echo "[INFO] Backup restore test successful: $LATEST_BACKUP" >> "$LOG"
else
    echo "[ALERT] Backup restore failed!" >> "$LOG"
fi

rm -rf "$TMP_RESTORE"
echo "[INFO] Restore validation finished" >> "$LOG"
