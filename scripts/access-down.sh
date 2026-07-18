#!/usr/bin/env bash


set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${ROOT_DIR}/configs/access.env"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
pass(){ echo -e "${GREEN}[PASS]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
fail(){ echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

echo
echo "=========================================================="
echo "      Atlas Nexus - Stop Cloudflare Tunnel"
echo "=========================================================="
echo


PID_PATH="${ROOT_DIR}/${PID_FILE}"
URL_PATH="${ROOT_DIR}/${URL_FILE}"

if [[ ! -f "$PID_PATH" ]]; then
    warn "No PID file found."

    # Clean up stale URL if present
    [[ -f "$URL_PATH" ]] && rm -f "$URL_PATH"

    exit 0
fi

PID=$(cat "$PID_PATH")



if kill -0 "$PID" >/dev/null 2>&1; then

    info "Stopping Cloudflare Tunnel (PID ${PID})..."

    kill "$PID"

    # Wait up to 10 seconds for clean shutdown
    for i in {1..10}; do
        if ! kill -0 "$PID" >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    # Force kill if still running
    if kill -0 "$PID" >/dev/null 2>&1; then
        warn "Tunnel did not exit gracefully. Force stopping..."
        kill -9 "$PID"
    fi

    pass "Cloudflare Tunnel stopped."

else

    warn "Process ${PID} is no longer running."

fi



rm -f "$PID_PATH"
rm -f "$URL_PATH"

pass "Runtime files cleaned."

echo
echo "=========================================================="
echo "Cloudflare Tunnel stopped successfully."
echo "=========================================================="
