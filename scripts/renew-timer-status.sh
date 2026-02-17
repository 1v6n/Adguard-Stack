#!/usr/bin/env bash
set -euo pipefail

service_name="adguard-renew"

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is not available on this host." >&2
  exit 1
fi

echo "== Timer status =="
systemctl status "${service_name}.timer" --no-pager || true

echo
echo "== Service status =="
systemctl status "${service_name}.service" --no-pager || true

echo
echo "== Next/last runs =="
systemctl list-timers --all | grep "${service_name}" || true
