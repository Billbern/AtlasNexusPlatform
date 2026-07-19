#!/usr/bin/env bash

###############################################################################
# Atlas Nexus - LiteLLM Decommission
#
# Stops the LiteLLM container.
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
 
###############################################################################
# Banner
###############################################################################
 
echo
echo "=========================================================="
echo "            Atlas Nexus - LiteLLM Decommission"
echo "=========================================================="
echo
 
###############################################################################
# 1. Container Status
###############################################################################
 
step "Container Status"
 
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    info "Stopping LiteLLM..."
    make -C "${ROOT_DIR}" litellm-down
    ok "LiteLLM container stopped."
else
    ok "LiteLLM container is already stopped."
fi
 
###############################################################################
# Summary
###############################################################################
 
echo
echo "=========================================================="
echo "         Atlas Nexus - LiteLLM Decommission Complete"
echo "=========================================================="
echo