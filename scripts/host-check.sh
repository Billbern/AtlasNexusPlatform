#!/usr/bin/env bash

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

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
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
    pass "$(docker --version)"
else
    fail "Docker is not installed."
fi

###############################################################################
# Docker Daemon
###############################################################################

info "Checking Docker daemon..."

if docker info >/dev/null 2>&1; then
    pass "Docker daemon is running."
else
    fail "Docker daemon is not running or is not accessible."
fi

###############################################################################
# Docker Compose
###############################################################################

info "Checking Docker Compose..."

if docker compose version >/dev/null 2>&1; then
    pass "$(docker compose version)"
else
    fail "Docker Compose plugin is missing."
fi

###############################################################################
# NVIDIA GPU
###############################################################################

info "Checking NVIDIA GPU..."

if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    pass "GPU detected: ${GPU_NAME}"
else
    warn "nvidia-smi not found. GPU acceleration may be unavailable."
fi

###############################################################################
# NVIDIA Container Toolkit
###############################################################################

info "Checking NVIDIA Container Toolkit..."

if docker info 2>/dev/null | grep -qi nvidia; then
    pass "NVIDIA container runtime detected."
else
    warn "NVIDIA container runtime not detected."
fi

###############################################################################
# Disk Space
###############################################################################

info "Checking disk space..."

AVAILABLE=$(df -BG . | awk 'NR==2 {gsub("G","",$4); print $4}')

if [ "$AVAILABLE" -ge 50 ]; then
    pass "${AVAILABLE} GB available."
else
    warn "Only ${AVAILABLE} GB available."
fi

###############################################################################
# Memory
###############################################################################

info "Checking system memory..."

MEMORY=$(free -g | awk '/^Mem:/ {print $2}')

if [ "$MEMORY" -ge 16 ]; then
    pass "${MEMORY} GB RAM detected."
else
    warn "Only ${MEMORY} GB RAM detected."
fi

###############################################################################
# Summary
###############################################################################

echo
echo "=========================================================="
echo "                 Host Check Summary"
echo "=========================================================="

echo -e "${GREEN}Passed:${NC} ${PASS}"
echo -e "${RED}Failed:${NC} ${FAIL}"

echo

if [ "${FAIL}" -gt 0 ]; then
    echo -e "${RED}Host readiness check failed.${NC}"
    exit 1
fi

echo -e "${GREEN}Host is ready for Atlas Nexus.${NC}"
exit 0