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

: "${PUBLIC_DOMAIN:?Missing PUBLIC_DOMAIN in .env}"
: "${DUCKDNS_TOKEN:?Missing DUCKDNS_TOKEN in .env}"
: "${LETSENCRYPT_EMAIL:?Missing LETSENCRYPT_EMAIL in .env}"

staging_flag=()
if [[ "${LETSENCRYPT_STAGING:-false}" == "true" ]]; then
  staging_flag=(--staging)
fi

echo "Issuing Let's Encrypt certificate for $PUBLIC_DOMAIN"
docker run --rm \
  -v "$ROOT_DIR/letsencrypt:/etc/letsencrypt" \
  -v "$ROOT_DIR/letsencrypt/logs:/var/log/letsencrypt" \
  infinityofspace/certbot_dns_duckdns:latest \
  certonly \
    --non-interactive \
    --agree-tos \
    --email "$LETSENCRYPT_EMAIL" \
    --preferred-challenges dns \
    --authenticator dns-duckdns \
    --dns-duckdns-token "$DUCKDNS_TOKEN" \
    --dns-duckdns-propagation-seconds 120 \
    -d "$PUBLIC_DOMAIN" \
    "${staging_flag[@]}"

if docker compose ps --services --filter status=running | grep -qx "nginx"; then
  echo "Restarting nginx to load certificate"
  docker compose restart nginx
fi

echo "Let's Encrypt issuance completed"
