#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTAINERS_DIR="$BASE_DIR/data/containers"

mkdir -p "$CONTAINERS_DIR"

create_container_fs() {
    CONTAINER_ID="$1"
    CONTAINER_FS="$CONTAINERS_DIR/container_$CONTAINER_ID"

    mkdir -p "$CONTAINER_FS"
    mkdir -p "$CONTAINER_FS/rootfs"
    mkdir -p "$CONTAINER_FS/tmp"

    echo "$CONTAINER_FS"
}

case "$1" in
    create)
        if [ -z "$2" ]; then
            echo "Usage: $0 create <container_id>"
            exit 1
        fi
        create_container_fs "$2"
        ;;
    *)
        echo "Usage: $0 create <container_id>"
        ;;
esac
