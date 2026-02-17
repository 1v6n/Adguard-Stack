#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="${BACKUP_DIR}/adguard-stack-backup-${TIMESTAMP}.tar.gz"
KEEP_BACKUPS="${KEEP_BACKUPS:-7}"

mkdir -p "$BACKUP_DIR"

echo "Creating backup: $ARCHIVE"
tar -czf "$ARCHIVE" config letsencrypt

echo "Pruning old backups (keep last ${KEEP_BACKUPS})"
ls -1t "$BACKUP_DIR"/adguard-stack-backup-*.tar.gz 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm -f

echo "Backup completed"
