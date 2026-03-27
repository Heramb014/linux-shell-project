#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTAINERS_DIR="$BASE_DIR/data/containers"

save_pid() {
    CONTAINER_ID="$1"
    PID="$2"

    echo "$PID" > "$CONTAINERS_DIR/container_$CONTAINER_ID/pid"
}

get_pid() {
    CONTAINER_ID="$1"

    if [ -f "$CONTAINERS_DIR/container_$CONTAINER_ID/pid" ]; then
        cat "$CONTAINERS_DIR/container_$CONTAINER_ID/pid"
    else
        echo "No PID found"
    fi
}

case "$1" in
    save)
        save_pid "$2" "$3"
        ;;
    get)
        get_pid "$2"
        ;;
    *)
        echo "Usage:"
        echo "$0 save <container_id> <pid>"
        echo "$0 get <container_id>"
        ;;
esac
