#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$BASE_DIR/logs/linux-monitor.log"
TAG="linux-monitor"

log() {
    local lvl="$1"; shift
    local msg="$*"
    local line="[$(date '+%F %T')] [$lvl] $msg"
    echo "$line" >> "$LOG"
    logger -t "$TAG" "$line" 2>/dev/null || true
}

log INFO "===== User and Permission Audit started ====="

# 1. UID 0 users
log INFO "Checking for UID 0 users"
awk -F: '$3 == 0 {print $1}' /etc/passwd | while read u; do
    log WARN "UID 0 user detected: $u"
done

# 2. Passwordless accounts
log INFO "Checking for passwordless accounts"
awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null | while read u; do
    log WARN "Passwordless or locked account: $u"
done

# 3. Users with sudo access
log INFO "Checking sudo access"
getent group sudo | awk -F: '{print $4}' | tr ',' '\n' | while read u; do
    [ -n "$u" ] && log WARN "User with sudo access: $u"
done

# 4. World-writable files
log INFO "Scanning for world-writable files"
find / -xdev -type f -perm -0002 2>/dev/null | head -n 20 | while read f; do
    log WARN "World-writable file: $f"
done

log INFO "===== User and Permission Audit finished ====="
