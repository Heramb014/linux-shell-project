#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$BASE_DIR/data/logs"

mkdir -p "$LOG_DIR"

CMD="$*"

if [ -z "$CMD" ]; then
    echo "Usage: $0 <command>"
    exit 1
fi

CONTAINER_ID=$(date +%s)
LOG_FILE="$LOG_DIR/container_${CONTAINER_ID}.log"

echo "Starting container $CONTAINER_ID with command: $CMD"

sudo unshare --fork --pid --mount-proc bash -c "$CMD" > "$LOG_FILE" 2>&1

echo "Container $CONTAINER_ID finished"
echo "Logs saved to $LOG_FILE"
