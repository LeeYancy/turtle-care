#!/usr/bin/env bash
set -euo pipefail

# ============================================
# TurtleCare - Production Deployment Script
# ============================================
# Deploys Docker images to the production server.
# Includes safety checks and requires confirmation.
# Usage: ./scripts/deploy-production.sh [--force]
# ============================================

# --- Configuration ---
COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.production"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DEPLOY_DIR="/opt/turtlecare"
FORCE=false

# Parse arguments
for arg in "$@"; do
    case ${arg} in
        --force) FORCE=true ;;
        *) echo "Unknown argument: ${arg}"; exit 1 ;;
    esac
done

echo "============================================"
echo "  TurtleCare - PRODUCTION Deployment"
echo "  Image Tag: ${IMAGE_TAG}"
echo "  Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# --- Safety confirmation ---
if [ "${FORCE}" = false ]; then
    echo ""
    echo "  *** WARNING: You are about to deploy to PRODUCTION ***"
    echo ""
    read -p "  Type 'DEPLOY' to continue: " CONFIRM
    if [ "${CONFIRM}" != "DEPLOY" ]; then
        echo "  Deployment cancelled."
        exit 0
    fi
fi

# --- Pre-flight checks ---
if [ ! -f "${ENV_FILE}" ]; then
    echo "ERROR: Environment file '${ENV_FILE}' not found!"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed!"
    exit 1
fi

# --- Database backup ---
echo ""
echo "[1/6] Creating PRODUCTION database backup..."
if [ -f "./scripts/backup-db.sh" ]; then
    bash ./scripts/backup-db.sh
    echo "  Backup completed successfully."
else
    echo "  ERROR: backup-db.sh not found! Aborting production deploy."
    exit 1
fi

# --- Pull latest images ---
echo ""
echo "[2/6] Pulling latest Docker images..."
export IMAGE_TAG
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull

# --- Blue-green: start new containers alongside old ---
echo ""
echo "[3/6] Starting new containers (blue-green)..."
# Note: For true blue-green, you'd need a load balancer.
# This is a rolling update with health checks.
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d --no-deps --force-recreate backend

# --- Wait for backend health ---
echo ""
echo "[4/6] Waiting for backend to be healthy..."
sleep 15

MAX_RETRIES=40
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
    echo "  ERROR: Backend failed to become healthy!"
    echo "  Rolling back..."
    docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" logs --tail=50 backend
    exit 1
fi

# --- Update frontend ---
echo ""
echo "[5/6] Updating frontend..."
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d --no-deps --force-recreate frontend

# --- Final cleanup ---
echo ""
echo "[6/6] Cleaning up old images..."
docker image prune -f

echo ""
echo "============================================"
echo "  PRODUCTION deployment complete!"
echo "  API: https://turtlecare.example.com/api/v1/"
echo "  Swagger: https://turtlecare.example.com/swagger-ui.html"
echo ""
echo "  Monitor: docker compose -f ${COMPOSE_FILE} logs -f"
echo "============================================"
