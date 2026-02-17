#!/usr/bin/env bash
set -euo pipefail

service_name="adguard-renew"
service_path="/etc/systemd/system/${service_name}.service"
timer_path="/etc/systemd/system/${service_name}.timer"
DRY_RUN="${DRY_RUN:-false}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is not available; nothing to uninstall." >&2
  exit 0
fi

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] $*"
  else
    eval "$*"
  fi
}

echo "Stopping and disabling ${service_name}.timer"
run_cmd "systemctl disable --now ${service_name}.timer >/dev/null 2>&1 || true"

echo "Stopping and disabling ${service_name}.service"
run_cmd "systemctl disable --now ${service_name}.service >/dev/null 2>&1 || true"

if [[ -f "$timer_path" ]]; then
  echo "Removing $timer_path"
  run_cmd "rm -f '$timer_path'"
fi

if [[ -f "$service_path" ]]; then
  echo "Removing $service_path"
  run_cmd "rm -f '$service_path'"
fi

echo "Reloading systemd daemon"
run_cmd "systemctl daemon-reload"

echo "Uninstall completed"
