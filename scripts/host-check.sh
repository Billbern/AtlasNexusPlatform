#!/usr/bin/env bash

###############################################################################
# Atlas Nexus - Host Readiness Check
###############################################################################

set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL++))
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo
echo "=========================================================="
echo "            Atlas Nexus - Host Readiness Check"
echo "=========================================================="
echo

###############################################################################
# Docker
###############################################################################

info "Checking Docker..."

if command -v docker >/dev/null 2>&1; then
    VERSION=$(docker --version)
    pass "$VERSION"
else
    fail "Docker is not installed."
fi

###############################################################################
# Docker Compose
###############################################################################

info "Checking Docker Compose..."

if docker compose version >/dev/null 2>&1; then
    VERSION=$(docker compose version)
    pass "$VERSION"
else
    fail "Docker Compose plugin is not installed."
fi

###############################################################################
# NVIDIA Driver
###############################################################################

info "Checking NVIDIA Driver..."

if command -v nvidia-smi >/dev/null 2>&1; then
    GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
    pass "GPU Detected: $GPU"
else
    fail "nvidia-smi not found."
fi

###############################################################################
# Docker GPU Runtime
###############################################################################

info "Checking Docker GPU Access..."

if docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
    pass "Docker can access the GPU."
else
    fail "Docker cannot access the GPU."
fi

###############################################################################
# Summary
###############################################################################

echo
echo "=========================================================="
echo "Summary"
echo "=========================================================="

echo "Passed : $PASS"
echo "Failed : $FAIL"

echo

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}Host is ready for Atlas Nexus.${NC}"
    exit 0
else
    echo -e "${RED}Host is NOT ready.${NC}"
    exit 1
fi