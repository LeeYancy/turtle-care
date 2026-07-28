#!/usr/bin/env bash
set -euo pipefail

# ============================================
# TurtleCare - Database Backup Script
# ============================================
# Creates a timestamped backup of the PostgreSQL database.
# Retains the last 7 days of backups.
# Usage: ./scripts/backup-db.sh
# ============================================

# --- Configuration ---
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DB_CONTAINER="${DB_CONTAINER:-turtlecare-postgres-prod}"
DB_NAME="${DB_NAME:-turtlecare}"
DB_USER="${DB_USER:-turtlecare}"
RETENTION_DAYS=7
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="${BACKUP_DIR}/turtlecare_${TIMESTAMP}.sql.gz"

echo "============================================"
echo "  TurtleCare - Database Backup"
echo "  Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# --- Create backup directory ---
mkdir -p "${BACKUP_DIR}"

# --- Check if container is running ---
if ! docker ps --format '{{.Names}}' | grep -q "${DB_CONTAINER}"; then
    echo "WARNING: Database container '${DB_CONTAINER}' is not running."
    echo "  Trying alternative container name..."
    DB_CONTAINER="turtlecare-postgres"
    if ! docker ps --format '{{.Names}}' | grep -q "${DB_CONTAINER}"; then
        echo "ERROR: No PostgreSQL container found!"
        exit 1
    fi
fi

# --- Create backup ---
echo ""
echo "[1/3] Creating database backup..."
docker exec "${DB_CONTAINER}" \
    pg_dump -U "${DB_USER}" -d "${DB_NAME}" --no-owner --no-acl \
    | gzip > "${BACKUP_FILE}"

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "  Backup created: ${BACKUP_FILE} (${BACKUP_SIZE})"

# --- Verify backup ---
echo ""
echo "[2/3] Verifying backup..."
if gzip -t "${BACKUP_FILE}" 2>/dev/null; then
    echo "  Backup integrity: OK"
else
    echo "  ERROR: Backup file is corrupted!"
    exit 1
fi

# --- Cleanup old backups ---
echo ""
echo "[3/3] Cleaning up backups older than ${RETENTION_DAYS} days..."
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "turtlecare_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -print -delete | wc -l)
echo "  Deleted ${DELETED_COUNT} old backup(s)."

# --- List remaining backups ---
REMAINING=$(find "${BACKUP_DIR}" -name "turtlecare_*.sql.gz" -type f | wc -l)
echo "  Remaining backups: ${REMAINING}"

echo ""
echo "============================================"
echo "  Backup complete!"
echo "============================================"
