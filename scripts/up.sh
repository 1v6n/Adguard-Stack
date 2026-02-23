#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
INSTALL_RENEW_TIMER="true"

if [[ -r "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

echo "Starting services..."
docker compose up -d adguard duckdns nginx

if [[ "${INSTALL_RENEW_TIMER:-true}" == "false" ]]; then
  echo "Systemd timer disabled; starting fallback renewal container."
  docker compose up -d certbot-renew
else
  docker compose stop certbot-renew >/dev/null 2>&1 || true
fi

echo "Current status:"
docker compose ps
