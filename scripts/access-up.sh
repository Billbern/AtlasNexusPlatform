#!/usr/bin/env bash


set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${ROOT_DIR}/configs/access.env"

mkdir -p "${ROOT_DIR}/runtime"

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
echo "      Atlas Nexus - Cloudflare Tunnel"
echo "=========================================================="
echo



command -v "${CLOUDFLARED_BIN}" >/dev/null \
    || fail "cloudflared is not installed. Run make access-install"


if [[ -f "${ROOT_DIR}/${PID_FILE}" ]]; then

    PID=$(cat "${ROOT_DIR}/${PID_FILE}")

    if kill -0 "$PID" 2>/dev/null; then
        fail "Tunnel already running (PID ${PID})"
    fi

    rm -f "${ROOT_DIR}/${PID_FILE}"
fi

rm -f "${ROOT_DIR}/${URL_FILE}"
rm -f "${ROOT_DIR}/${LOG_FILE}"



info "Starting Cloudflare Quick Tunnel..."

nohup "${CLOUDFLARED_BIN}" tunnel \
    --no-autoupdate \
    --url "http://${TARGET_HOST}:${TARGET_PORT}" \
    > "${ROOT_DIR}/${LOG_FILE}" 2>&1 &

PID=$!

echo "$PID" > "${ROOT_DIR}/${PID_FILE}"



info "Waiting for tunnel..."

URL=""

for i in {1..30}; do

    if grep -oE 'https://[-a-zA-Z0-9]+\.trycloudflare\.com' \
        "${ROOT_DIR}/${LOG_FILE}" >/dev/null 2>&1; then

        URL=$(grep -oE 'https://[-a-zA-Z0-9]+\.trycloudflare\.com' \
            "${ROOT_DIR}/${LOG_FILE}" | head -1)

        break

    fi

    sleep 1

done

[[ -n "$URL" ]] || fail "Cloudflare tunnel failed to start."

echo "$URL" > "${ROOT_DIR}/${URL_FILE}"



pass "Tunnel running."

echo
echo "Public URL"
echo "----------"
echo "$URL"

echo
echo "OpenAI Endpoint"
echo "---------------"
echo "$URL/v1"

echo
echo "Health"
echo "------"
echo "$URL/health"

echo
echo "PID"
echo "---"
echo "$PID"
