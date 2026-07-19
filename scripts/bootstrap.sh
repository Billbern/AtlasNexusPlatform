#!/usr/bin/env bash

###############################################################################
# Atlas Nexus - Bootstrap
#
# One-shot setup that runs the full provisioning pipeline:
#   host-install → host-check → storage-init → vllm-up → vllm-health → access
#
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

DO_HOST=true
DO_STORAGE=true
DO_VLLM=true
DO_ACCESS=true
SKIP_CHECK=false
SKIP_VLLM_START=false

###############################################################################
# Usage
###############################################################################

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --all            Run everything (default)
  --host           Install host dependencies only
  --storage        Initialize storage only
  --vllm           Start vLLM only
  --access         Install cloudflared + start tunnel only
  --skip-check     Skip host-check (useful if already verified)
  --skip-vllm      Skip starting vLLM
  --help, -h       Show this help

Examples:
  $0                     # Full pipeline
  $0 --host --storage    # Host + storage, skip vLLM and access
  $0 --vllm --access     # Start vLLM and tunnel only
EOF
    exit 0
}

###############################################################################
# Parse arguments
###############################################################################

if [[ $# -eq 0 ]]; then
    DO_HOST=true
    DO_STORAGE=true
    DO_VLLM=true
    DO_ACCESS=true
else
    DO_HOST=false
    DO_STORAGE=false
    DO_VLLM=false
    DO_ACCESS=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                DO_HOST=true
                DO_STORAGE=true
                DO_VLLM=true
                DO_ACCESS=true
                ;;
            --host)       DO_HOST=true ;;
            --storage)    DO_STORAGE=true ;;
            --vllm)       DO_VLLM=true ;;
            --access)     DO_ACCESS=true ;;
            --skip-check) SKIP_CHECK=true ;;
            --skip-vllm)  SKIP_VLLM_START=true ;;
            --help|-h)    usage ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
        shift
    done
fi

###############################################################################
# Banner
###############################################################################

echo
echo "=========================================================="
echo "            Atlas Nexus - Bootstrap"
echo "=========================================================="
echo

if [[ "$DO_HOST" == true ]]; then
    echo "  • Host provisioning"
fi
if [[ "$DO_STORAGE" == true ]]; then
    echo "  • Storage initialization"
fi
if [[ "$DO_VLLM" == true ]]; then
    echo "  • vLLM deployment"
fi
if [[ "$DO_ACCESS" == true ]]; then
    echo "  • Cloudflare tunnel"
fi
echo

###############################################################################
# 1. Host Installation
###############################################################################

if [[ "$DO_HOST" == true ]]; then

    step "Host Installation"

    if command -v docker >/dev/null 2>&1; then
        ok "Docker already installed ($(docker --version))."
    else
        info "Installing Docker and NVIDIA Toolkit..."
        sudo "${SCRIPT_DIR}/host-install.sh"
        ok "Host installation complete."
    fi

    if [[ "$SKIP_CHECK" == false ]]; then
        step "Host Readiness Check"
        "${SCRIPT_DIR}/host-check.sh" || fail "Host check failed."
    else
        info "Skipping host check (--skip-check)."
    fi

fi

###############################################################################
# 2. Storage Initialization
###############################################################################

if [[ "$DO_STORAGE" == true ]]; then

    step "Storage Initialization"

    if [[ -d "${ROOT_DIR}/storage/models" ]] && \
       [[ -d "${ROOT_DIR}/storage/vllm/logs" ]]; then
        ok "Storage directories already exist."
    else
        "${SCRIPT_DIR}/storage-init.sh"
        ok "Storage initialized."
    fi

fi

###############################################################################
# 3. vLLM
###############################################################################

if [[ "$DO_VLLM" == true ]]; then

    step "vLLM Deployment"

    CONTAINER_NAME="${CONTAINER_NAME:-atlas-nexus-vllm}"

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        ok "vLLM container '${CONTAINER_NAME}' is already running."
    else
        if [[ "$SKIP_VLLM_START" == true ]]; then
            info "Skipping vLLM start (--skip-vllm)."
        else
            info "Starting vLLM..."
            make -C "${ROOT_DIR}" vllm-up
            ok "vLLM container started."
        fi
    fi

    step "vLLM Health Check"

    if "${SCRIPT_DIR}/vllm-health.sh"; then
        ok "vLLM is healthy."
    else
        warn "vLLM is not yet healthy — it may still be loading the model."
        warn "Run 'make vllm-health' later to check again."
    fi

fi

    step "LiteLLM Deployment"

    CONTAINER_NAME="${CONTAINER_NAME:-atlas-nexus-litellm}"

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        ok "LiteLLM container '${CONTAINER_NAME}' is already running."
    else
        if [[ "$SKIP_VLLM_START" == true ]]; then
            info "Skipping LiteLLM start (--skip-vllm)."
        else
            info "Starting LiteLLM..."
            make -C "${ROOT_DIR}" litellm-up
            ok "LiteLLM container started."
        fi
    fi

    step "LiteLLM Health Check"

    if "${SCRIPT_DIR}/litellm-health.sh"; then
        ok "LiteLLM is healthy."
    else
        warn "LiteLLM is not yet healthy — it may still be loading the model."
        warn "Run 'make litellm-health' later to check again."
    fi

###############################################################################
# 4. Access (Cloudflare Tunnel)
###############################################################################

if [[ "$DO_ACCESS" == true ]]; then

    step "Cloudflare Tunnel"

    if command -v cloudflared >/dev/null 2>&1; then
        ok "cloudflared already installed ($(cloudflared --version | head -1))."
    else
        info "Installing cloudflared..."
        sudo "${SCRIPT_DIR}/access-install.sh"
        ok "cloudflared installed."
    fi

    PID_FILE="${ROOT_DIR}/runtime/cloudflared.pid"

    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        ok "Cloudflare tunnel is already running."
        cat "${ROOT_DIR}/runtime/cloudflared.url" 2>/dev/null || true
    else
        info "Starting Cloudflare tunnel..."
        "${SCRIPT_DIR}/access-up.sh"
        ok "Tunnel started."
    fi

fi

###############################################################################
# Summary
###############################################################################

echo
echo "=========================================================="
echo "         Atlas Nexus - Bootstrap Complete"
echo "=========================================================="
echo

if [[ "$DO_VLLM" == true ]]; then
    echo "  Local API  : http://localhost:8000/v1"
fi

if [[ "$DO_ACCESS" == true ]] && [[ -f "${ROOT_DIR}/runtime/cloudflared.url" ]]; then
    PUBLIC_URL=$(cat "${ROOT_DIR}/runtime/cloudflared.url")
    echo "  Public URL : ${PUBLIC_URL}"
    echo "  API        : ${PUBLIC_URL}/v1"
fi

echo
echo "  Commands:"
echo "    make vllm-health     Check vLLM status"
echo "    make vllm-logs       Follow vLLM logs"
echo "    make access-down     Stop Cloudflare tunnel"
echo "    make vllm-down       Stop vLLM"
echo