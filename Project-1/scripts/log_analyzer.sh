#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$BASE_DIR/logs/linux-monitor.log"
TAG="linux-monitor"

# how many "top" results to show
TOP_N=10

mkdir -p "$BASE_DIR/logs"
touch "$LOG"

log() {
  local lvl="$1"; shift
  local msg="$*"
  local line="[$(date '+%F %T')] [$lvl] $msg"
  echo "$line" >> "$LOG"
  logger -t "$TAG" "$line" 2>/dev/null || true
}

section() {
  log INFO "----- $* -----"
  echo
  echo "===== $* ====="
}

# ----- SSH FAILED ATTEMPTS -----
analyze_ssh() {
  section "SSH Failed Login Analysis"

  # Ubuntu usually has /var/log/auth.log
  if [[ -f /var/log/auth.log ]]; then
    local src="/var/log/auth.log"
    log INFO "Using auth log: $src"
    echo "Using: $src"

    # Failed password / invalid user attempts (top IPs)
    # typical formats contain: "Failed password" ... "from <IP>"
    grep -E "Failed password|Invalid user|authentication failure" "$src" 2>/dev/null \
      | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" \
      | awk '{print $2}' \
      | sort | uniq -c | sort -nr | head -n "$TOP_N" \
      | awk '{printf "Failed SSH attempts: %s (count=%s)\n", $2, $1}'

  else
    # Fallback: use journalctl (systemd logs)
    log WARN "/var/log/auth.log not found; falling back to journalctl"
    echo "auth.log not found; using journalctl (last 24h)"

    journalctl -u ssh --since "24 hours ago" --no-pager 2>/dev/null \
      | grep -E "Failed password|Invalid user|authentication failure" \
      | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" \
      | awk '{print $2}' \
      | sort | uniq -c | sort -nr | head -n "$TOP_N" \
      | awk '{printf "Failed SSH attempts: %s (count=%s)\n", $2, $1}' || true
  fi
}

# ----- FREQUENT IP ACCESS -----
analyze_frequent_ips() {
  section "Frequent IP Access (SSH + Nginx if available)"

  # SSH accepted logins (auth.log)
  if [[ -f /var/log/auth.log ]]; then
    echo "Top SSH ACCEPTED login source IPs:"
    grep -E "Accepted password|Accepted publickey" /var/log/auth.log 2>/dev/null \
      | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" \
      | awk '{print $2}' \
      | sort | uniq -c | sort -nr | head -n "$TOP_N" \
      | awk '{printf "Accepted SSH: %s (count=%s)\n", $2, $1}' || true
  else
    echo "Top SSH ACCEPTED login source IPs (journalctl last 24h):"
    journalctl -u ssh --since "24 hours ago" --no-pager 2>/dev/null \
      | grep -E "Accepted password|Accepted publickey" \
      | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" \
      | awk '{print $2}' \
      | sort | uniq -c | sort -nr | head -n "$TOP_N" \
      | awk '{printf "Accepted SSH: %s (count=%s)\n", $2, $1}' || true
  fi

  echo
  if [[ -f /var/log/nginx/access.log ]]; then
    echo "Top Nginx client IPs (access.log):"
    awk '{print $1}' /var/log/nginx/access.log \
      | sort | uniq -c | sort -nr | head -n "$TOP_N" \
      | awk '{printf "Nginx access: %s (count=%s)\n", $2, $1}'
  else
    echo "Nginx access.log not found (skip)."
    log WARN "Nginx access.log not found; skipping nginx frequent IP analysis"
  fi
}

# ----- HTTP ERROR PATTERNS -----
analyze_http_errors() {
  section "HTTP Error Patterns (Nginx)"

  if [[ ! -f /var/log/nginx/access.log ]]; then
    echo "Nginx access.log not found. Skipping HTTP error analysis."
    log WARN "HTTP error analysis skipped; /var/log/nginx/access.log missing"
    return
  fi

  log INFO "Analyzing /var/log/nginx/access.log for HTTP 4xx/5xx"

  echo "Top HTTP error status codes:"
  # $9 is status in default combined log format
  awk '$9 ~ /^[45][0-9][0-9]$/ {print $9}' /var/log/nginx/access.log \
    | sort | uniq -c | sort -nr | head -n "$TOP_N" \
    | awk '{printf "HTTP %s (count=%s)\n", $2, $1}'

  echo
  echo "Top client IPs generating errors:"
  awk '$9 ~ /^[45][0-9][0-9]$/ {print $1}' /var/log/nginx/access.log \
    | sort | uniq -c | sort -nr | head -n "$TOP_N" \
    | awk '{printf "Error IP: %s (count=%s)\n", $2, $1}'

  echo
  echo "Top requested paths causing errors:"
  # $7 is path in default format: "GET /path HTTP/1.1"
  awk '$9 ~ /^[45][0-9][0-9]$/ {print $7}' /var/log/nginx/access.log \
    | sort | uniq -c | sort -nr | head -n "$TOP_N" \
    | awk '{printf "Error path: %s (count=%s)\n", $2, $1}'
}

main() {
  log INFO "Log analyzer started"
  analyze_ssh
  analyze_frequent_ips
  analyze_http_errors
  log INFO "Log analyzer finished"
}

main "$@"
