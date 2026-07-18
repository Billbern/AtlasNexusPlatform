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
# Docker CLI
###############################################################################

info "Checking Docker CLI..."

if command -v docker >/dev/null 2>&1; then
    pass "$(docker --version)"
else
    fail "Docker CLI not installed."
fi

###############################################################################
# Docker Daemon
###############################################################################

info "Checking Docker daemon..."

if docker info >/dev/null 2>&1; then
    pass "Docker daemon is running."
else
    fail "Docker daemon is not running."
fi

###############################################################################
# Docker Compose
###############################################################################

info "Checking Docker Compose..."

if docker compose version >/dev/null 2>&1; then
    pass "$(docker compose version)"
else
    fail "Docker Compose plugin missing."
fi

###############################################################################
# NVIDIA Driver
###############################################################################

info "Checking NVIDIA driver..."

if command -v nvidia-smi >/dev/null 2>&1; then

    if GPU=$(nvidia-smi \
        --query-gpu=name \
        --format=csv,noheader \
        2>/dev/null | head -1); then

        pass "GPU detected: ${GPU}"

    else

        fail "nvidia-smi exists but driver is broken."

    fi

else

    fail "nvidia-smi not installed."

fi

###############################################################################
# NVIDIA Container Runtime
###############################################################################

info "Checking NVIDIA Container Runtime..."

if command -v nvidia-container-runtime >/dev/null 2>&1; then
    pass "nvidia-container-runtime installed."
else
    fail "nvidia-container-runtime missing."
fi

###############################################################################
# NVIDIA CTK
###############################################################################

info "Checking NVIDIA Container Toolkit..."

if command -v nvidia-ctk >/dev/null 2>&1; then
    pass "$(nvidia-ctk --version)"
else
    fail "nvidia-ctk missing."
fi

###############################################################################
# Docker Runtime Registration
###############################################################################

info "Checking Docker runtime registration..."

if docker info | grep -q " nvidia"; then
    pass "Docker NVIDIA runtime registered."
else
    fail "Docker NVIDIA runtime not registered."
fi

###############################################################################
# Docker Daemon Configuration
###############################################################################

info "Checking Docker daemon configuration..."

if [ -f /etc/docker/daemon.json ]; then
    pass "/etc/docker/daemon.json found."
else
    fail "Docker daemon.json missing."
fi

###############################################################################
# GPU Containers
###############################################################################

info "Checking Docker GPU access..."

if docker run --rm --gpus all \
    nvidia/cuda:12.4.1-base-ubuntu22.04 \
    nvidia-smi >/dev/null 2>&1
then
    pass "Docker GPU support working."
else
    fail "Docker cannot launch GPU containers."
fi

###############################################################################
# Disk
###############################################################################

info "Checking disk space..."

AVAILABLE=$(df -BG / | awk 'NR==2{gsub("G","",$4);print $4}')

if [ "$AVAILABLE" -ge 50 ]; then
    pass "${AVAILABLE} GB free."
else
    warn "${AVAILABLE} GB free."
fi

###############################################################################
# RAM
###############################################################################

info "Checking RAM..."

MEM=$(free -g | awk '/^Mem:/{print $2}')

if [ "$MEM" -ge 16 ]; then
    pass "${MEM} GB RAM."
else
    warn "${MEM} GB RAM."
fi

###############################################################################
# Internet
###############################################################################

info "Checking Internet..."

if curl -fsSL https://huggingface.co >/dev/null; then
    pass "Internet connectivity OK."
else
    warn "Unable to reach Hugging Face."
fi

###############################################################################
# Summary
###############################################################################

echo
echo "=========================================================="
echo "                 Host Check Summary"
echo "=========================================================="

echo "Passed : ${PASS}"
echo "Failed : ${FAIL}"

echo

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Host is NOT ready.${NC}"
    exit 1
fi

echo -e "${GREEN}Host is ready for Atlas Nexus.${NC}"
exit 0
