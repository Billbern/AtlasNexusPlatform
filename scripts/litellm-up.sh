#!/usr/bin/env bash

###############################################################################
# Atlas Nexus - LiteLLM Deployment
#
# Starts the LiteLLM container and verifies it's healthy.
# Idempotent — safe to run multiple times.
###############################################################################
 
set -euo pipefail
 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
 
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
 
info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[ OK ]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }
step()  { echo; echo -e "${BLUE}━━━ $1 ━━━${NC}"; }
 
###############################################################################
# Defaults
###############################################################################
 
CONTAINER_NAME="${CONTAINER_NAME:-atlas-nexus-litellm}"
IMAGE="${IMAGE:-litellm/litellm:main}"
PORT="${PORT:-4000}"
 
###############################################################################
# Banner
###############################################################################
 
echo
echo "=========================================================="
echo "            Atlas Nexus - LiteLLM Deployment"
echo "=========================================================="
echo
 
###############################################################################
# 1. Container Status
###############################################################################
 
step "Container Status"
 
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    ok "LiteLLM container '${CONTAINER_NAME}' is already running."
else
    info "Starting LiteLLM..."
    docker compose -f compose/litellm/compose.yaml up -d
    ok "LiteLLM container started."
fi
 
###############################################################################
# 2. Health Check
###############################################################################
 
step "Health Check"
 
if "${SCRIPT_DIR}/litellm-health.sh"; then
    ok "LiteLLM is healthy."
else
    warn "LiteLLM is not yet healthy — it may still be loading the model."
    warn "Run 'make litellm-health' later to check again."
fi
 
###############################################################################
# Summary
###############################################################################
 
echo
echo "=========================================================="
echo "         Atlas Nexus - LiteLLM Deployment Complete"
echo "=========================================================="
echo