#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$BASE_DIR/config/backup.conf"
FILES_CONFIG="$BASE_DIR/config/monitored_files.conf"
LOG="$BASE_DIR/logs/automation.log"

source "$CONFIG"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

tar -czf "$BACKUP_FILE" -T "$FILES_CONFIG"

echo "[$(date)] Backup created: $BACKUP_FILE" >> "$LOG"

find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -delete
echo "[$(date)] Old backups cleaned" >> "$LOG"
