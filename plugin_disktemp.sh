#!/bin/bash
# Disk temperature monitor with Discord alert trigger
# Requires: smartctl, tn-to-discord.py in same directory
# Usage: THRESHOLD=50 DISCORD_WEBHOOK_URL="..." ./disktemp.sh [--show-output] [--sender "MyBot"]

set -euo pipefail

SMARTCTL="${SMARTCTL:-/usr/sbin/smartctl}"
THRESHOLD="${THRESHOLD:-53}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DISCORD_SCRIPT="$SCRIPT_DIR/tn-to-discord.py"
SHOW_OUTPUT=false
SENDER_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --show-output)
      SHOW_OUTPUT=true
      shift
      ;;
    --sender)
      SENDER_ARG="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

get_temp_from_output() {
  awk '
    /^Temperature:[[:space:]]/ { if (match($0, /([0-9]+)/, a)) { print a[1]; exit } }
    /^Temperature[[:space:]]+Sensor/ { if (match($0, /([0-9]+)/, a)) { print a[1]; exit } }
    /^Current[[:space:]]+Composite/ { if (match($0, /([0-9]+)/, a)) { print a[1]; exit } }
    /^Current[[:space:]]+Drive/ { if (match($0, /([0-9]+)/, a)) { print a[1]; exit } }
    /^Drive[[:space:]]+Temperature/ { if (match($0, /([0-9]+)/, a)) { print a[1]; exit } }
    /^[[:space:]]*(194|190)[[:space:]]/ || /Temperature_Celsius/ || /Airflow_Temperature/ {
      for (i=NF; i>=1; i--) {
        if ($i ~ /^[0-9]+$/) { print $i; exit }
      }
    }
  '
}

read_temp() {
  local dev="$1" dtype="$2" out temp
  if [ -n "$dtype" ]; then
    out="$("$SMARTCTL" -A -d "$dtype" "$dev" 2>/dev/null || true)"
  else
    out="$("$SMARTCTL" -A "$dev" 2>/dev/null || true)"
  fi
  temp="$(printf '%s\n' "$out" | get_temp_from_output || true)"
  if [[ "$temp" =~ ^[0-9]+$ ]]; then
    echo "$temp"; return 0
  fi
  if [ "$dtype" = "scsi" ]; then
    out="$("$SMARTCTL" -A -d sat "$dev" 2>/dev/null || true)"
    temp="$(printf '%s\n' "$out" | get_temp_from_output || true)"
    if [[ "$temp" =~ ^[0-9]+$ ]]; then
      echo "$temp"; return 0
    fi
  fi
  out="$("$SMARTCTL" -l scttemp "$dev" 2>/dev/null || true)"
  temp="$(printf '%s\n' "$out" | awk "/Current Temperature/ { if (match(\$0, /([0-9]+)/, a)) { print a[1]; exit } }" || true)"
  [[ "$temp" =~ ^[0-9]+$ ]] && echo "$temp"
}

# Main
alert_needed=false
output="Disk temperature report (threshold: ${THRESHOLD}°C)\n---------------------------------------------"

while IFS= read -r line; do
  dev=$(echo "$line"  | awk '{print $1}')
  dtype=$(echo "$line"| awk '{for (i=2;i<=NF;i++) if ($i=="-d") {print $(i+1); exit}}')
  temp="$(read_temp "$dev" "${dtype:-}")"
  if [[ "$temp" =~ ^[0-9]+$ ]]; then
    if (( temp >= THRESHOLD )); then
      output+="\n$dev  ${temp}°C  🔥"
      alert_needed=true
    else
      output+="\n$dev  ${temp}°C"
    fi
  else
    output+="\n$dev  N/A"
  fi
done < <("$SMARTCTL" --scan)

if $SHOW_OUTPUT; then
  echo -e "$output"
fi

if $alert_needed; then
  if [[ -x "$DISCORD_SCRIPT" ]]; then
    if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
      if [[ -n "$SENDER_ARG" ]]; then
        python3 "$DISCORD_SCRIPT" -w "$DISCORD_WEBHOOK_URL" -s "$SENDER_ARG" -m "$(printf '%b' "${output}")"
      else
        python3 "$DISCORD_SCRIPT" -w "$DISCORD_WEBHOOK_URL" -m "$(printf '%b' "${output}")"
      fi
    else
      echo "ERROR: DISCORD_WEBHOOK_URL not set"
    fi
  else
    echo "ERROR: Discord script not found at $DISCORD_SCRIPT"
  fi
fi