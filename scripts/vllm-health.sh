#!/usr/bin/env bash

###############################################################################
# Atlas Nexus - vLLM Health Check
#
# Checks that the vLLM container is running and its /health endpoint responds.
# Exits 0 on success, 1 on failure.
###############################################################################

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    (( ++PASS ))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    (( ++FAIL ))
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo
echo "=========================================================="
echo "          Atlas Nexus - vLLM Health Check"
echo "=========================================================="
echo

###############################################################################
# Container Running
###############################################################################

info "Checking container status..."

CONTAINER_NAME="${CONTAINER_NAME:-atlas-nexus-vllm}"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    pass "Container '${CONTAINER_NAME}' is running."
else
    fail "Container '${CONTAINER_NAME}' is not running."
fi

###############################################################################
# Health Endpoint
###############################################################################

info "Checking /health endpoint..."

PORT="${PORT:-8000}"

if curl -fsSL "http://localhost:${PORT}/health" >/dev/null 2>&1; then
    pass "vLLM health endpoint responded."
else
    fail "vLLM health endpoint unreachable on port ${PORT}."
fi

###############################################################################
# Model List
###############################################################################

info "Checking /v1/models endpoint..."

if curl -fsSL "http://localhost:${PORT}/v1/models" >/dev/null 2>&1; then
    pass "vLLM model list endpoint responded."
else
    fail "vLLM model list endpoint unreachable."
fi

###############################################################################
# Summary
###############################################################################

echo
echo "=========================================================="
echo "              Health Check Summary"
echo "=========================================================="

echo "Passed : ${PASS}"
echo "Failed : ${FAIL}"

echo

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}vLLM is NOT healthy.${NC}"
    exit 1
fi

echo -e "${GREEN}vLLM is healthy.${NC}"
exit 0