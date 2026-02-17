#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

if [[ ! -r "$ENV_FILE" ]]; then
  echo "Cannot read env file: $ENV_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${DUCKDNS_TOKEN:?Missing DUCKDNS_TOKEN in .env}"

staging_flag=()
if [[ "${LETSENCRYPT_STAGING:-false}" == "true" ]]; then
  staging_flag=(--staging)
fi

before_sum="$(find "$ROOT_DIR/letsencrypt/live" -type f -name 'fullchain.pem' -exec sha256sum {} + 2>/dev/null | sha256sum | awk '{print $1}')"

echo "Running certbot renew"
docker run --rm \
  -v "$ROOT_DIR/letsencrypt:/etc/letsencrypt" \
  -v "$ROOT_DIR/letsencrypt/logs:/var/log/letsencrypt" \
  infinityofspace/certbot_dns_duckdns:latest \
  renew \
    --non-interactive \
    --preferred-challenges dns \
    --authenticator dns-duckdns \
    --dns-duckdns-token "$DUCKDNS_TOKEN" \
    --dns-duckdns-propagation-seconds 120 \
    "${staging_flag[@]}"

after_sum="$(find "$ROOT_DIR/letsencrypt/live" -type f -name 'fullchain.pem' -exec sha256sum {} + 2>/dev/null | sha256sum | awk '{print $1}')"

if [[ "$before_sum" != "$after_sum" ]]; then
  echo "Certificate files changed, restarting nginx"
  docker compose restart nginx
else
  echo "No certificate changes detected"
fi
