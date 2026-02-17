#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TAIL_LINES="${1:-100}"

echo "Showing logs for nginx and adguard (last ${TAIL_LINES} lines)..."
docker compose logs --tail="$TAIL_LINES" -f nginx adguard
