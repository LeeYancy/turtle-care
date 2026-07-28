#!/usr/bin/env bash
set -euo pipefail

# ============================================
# TurtleCare - Staging Deployment Script
# ============================================
# Deploys the latest Docker images to the staging server.
# Usage: ./scripts/deploy-staging.sh
# ============================================

# --- Configuration ---
COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.staging"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DEPLOY_DIR="/opt/turtlecare"

echo "============================================"
echo "  TurtleCare - Staging Deployment"
echo "  Image Tag: ${IMAGE_TAG}"
echo "  Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# --- Pre-flight checks ---
if [ ! -f "${ENV_FILE}" ]; then
    echo "ERROR: Environment file '${ENV_FILE}' not found!"
    echo "Create it with: cp .env.example ${ENV_FILE}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed!"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose V2 is not available!"
    exit 1
fi

# --- Pull latest images ---
echo ""
echo "[1/5] Pulling latest Docker images..."
export IMAGE_TAG
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull

# --- Database backup before deploy ---
echo ""
echo "[2/5] Creating database backup..."
if [ -f "./scripts/backup-db.sh" ]; then
    bash ./scripts/backup-db.sh
    echo "  Database backup completed."
else
    echo "  WARNING: backup-db.sh not found, skipping backup."
fi

# --- Stop existing containers ---
echo ""
echo "[3/5] Stopping existing containers..."
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" down --timeout 30

# --- Start new containers ---
echo ""
echo "[4/5] Starting new containers..."
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d --force-recreate

# --- Health check ---
echo ""
echo "[5/5] Waiting for services to be healthy..."
sleep 10

MAX_RETRIES=30
RETRY_COUNT=0

while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    HEALTHY=$(docker inspect --format='{{.State.Health.Status}}' turtlecare-backend-prod 2>/dev/null || echo "none")
    if [ "${HEALTHY}" = "healthy" ]; then
        echo "  Backend is healthy!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "  Waiting for backend... (${RETRY_COUNT}/${MAX_RETRIES})"
    sleep 5
done

if [ ${RETRY_COUNT} -ge ${MAX_RETRIES} ]; then
    echo "  WARNING: Backend did not become healthy within timeout."
    echo "  Check logs: docker compose -f ${COMPOSE_FILE} logs backend"
fi

# --- Cleanup old images ---
echo ""
echo "Cleaning up dangling images..."
docker image prune -f

echo ""
echo "============================================"
echo "  Staging deployment complete!"
echo "  API: http://$(hostname -I | awk '{print $1}')/api/v1/"
echo "  Swagger: http://$(hostname -I | awk '{print $1}')/swagger-ui.html"
echo "============================================"
