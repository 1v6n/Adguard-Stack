#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Service status"
docker compose ps

echo
echo "Validating Nginx config inside container"
docker compose exec nginx nginx -t

echo
echo "Compose configuration validation"
docker compose config > /dev/null

echo "All checks completed successfully"
