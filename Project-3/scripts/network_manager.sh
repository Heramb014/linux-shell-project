#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NETWORK_FILE="$BASE_DIR/data/network.db"

mkdir -p "$BASE_DIR/data"

allocate_ip() {
    CONTAINER_ID="$1"

    if [ ! -f "$NETWORK_FILE" ]; then
        echo "10.0.0.1" > "$NETWORK_FILE"
    fi

    LAST_IP=$(tail -n 1 "$NETWORK_FILE")

    IFS='.' read -r o1 o2 o3 o4 <<< "$LAST_IP"
    NEW_IP="$o1.$o2.$o3.$((o4+1))"

    echo "$NEW_IP" >> "$NETWORK_FILE"

    echo "$CONTAINER_ID $NEW_IP"
}

case "$1" in
    allocate)
        allocate_ip "$2"
        ;;
    *)
        echo "Usage: $0 allocate <container_id>"
        ;;
esac
