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

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[PASS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

echo
echo "=========================================================="
echo "      Atlas Nexus - Cloudflare Installation"
echo "=========================================================="
echo


if [[ $EUID -ne 0 ]]; then
    fail "Run with sudo."
fi



source /etc/os-release

[[ "$ID" == "ubuntu" ]] || fail "Only Ubuntu is currently supported."

case "$VERSION_ID" in
    22.04|24.04)
        ok "Ubuntu ${VERSION_ID}"
        ;;
    *)
        fail "Unsupported Ubuntu version: ${VERSION_ID}"
        ;;
esac



if command -v "${CLOUDFLARED_BIN}" >/dev/null 2>&1; then

    VERSION="$(${CLOUDFLARED_BIN} --version | head -1)"

    ok "Cloudflared already installed."
    echo "      ${VERSION}"

    exit 0

fi



info "Installing dependencies..."

apt-get update

apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release



info "Downloading cloudflared..."

ARCH="$(dpkg --print-architecture)"

case "$ARCH" in
    amd64)
        PKG="cloudflared-linux-amd64.deb"
        ;;
    arm64)
        PKG="cloudflared-linux-arm64.deb"
        ;;
    *)
        fail "Unsupported architecture: ${ARCH}"
        ;;
esac

wget -O /tmp/cloudflared.deb \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/${PKG}"



info "Installing cloudflared..."

dpkg -i /tmp/cloudflared.deb || apt-get install -fy

rm -f /tmp/cloudflared.deb



command -v cloudflared >/dev/null \
    || fail "cloudflared installation failed."

VERSION="$(cloudflared --version | head -1)"

ok "${VERSION}"

echo
echo "=========================================================="
echo "Cloudflare installation completed."
echo "=========================================================="
