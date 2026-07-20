#!/usr/bin/env bash

###############################################################################
# Atlas Nexus - Host Installer
#
# Supports:
#   - Ubuntu 22.04
#   - Ubuntu 24.04
#
# Installs:
#   - Base packages
#   - Docker
#   - Docker Compose
#   - NVIDIA Container Toolkit
#   - Docker NVIDIA Runtime
#
# Validates:
#   - Docker
#   - Docker Compose
#   - NVIDIA Driver
#   - NVIDIA Runtime
#   - GPU Containers
###############################################################################

set -euo pipefail

###############################################################################
# Root
###############################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo."
    exit 1
fi

# Attempt to run without sudo by checking if user is in docker group
if ! groups | grep -q '\bdocker\b'; then
    echo "Adding user to docker group..."
    usermod -aG docker $USER
fi

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){ echo -e "${GREEN}[ OK ]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
die(){ echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

echo
echo "=========================================================="
echo " Atlas Nexus Host Installation"
echo "=========================================================="
echo

###############################################################################
# Detect OS
###############################################################################

[[ -f /etc/os-release ]] || die "/etc/os-release not found"

source /etc/os-release

[[ "$ID" == "ubuntu" ]] || die "Unsupported OS: $ID"

case "$VERSION_ID" in
    22.04|24.04)
        ok "Ubuntu $VERSION_ID detected."
        ;;
    *)
        die "Unsupported Ubuntu version: $VERSION_ID"
        ;;
esac

###############################################################################
# Update
###############################################################################

info "Updating apt..."

apt-get update

###############################################################################
# Base Packages
###############################################################################

PACKAGES=(
    curl
    wget
    git
    unzip
    ca-certificates
    gnupg
    lsb-release
    software-properties-common
)

for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        ok "$pkg"
    else
        info "Installing $pkg..."
        apt-get install -y "$pkg"
    fi
done

###############################################################################
# NVIDIA Driver
###############################################################################

info "Checking NVIDIA driver..."

command -v nvidia-smi >/dev/null \
    || die "NVIDIA driver not installed."

GPU=$(nvidia-smi \
    --query-gpu=name \
    --format=csv,noheader | head -1)

ok "GPU: $GPU"

###############################################################################
# Docker
###############################################################################

if command -v docker >/dev/null 2>&1; then

    ok "Docker already installed."

else

    info "Installing Docker..."

    curl -fsSL https://get.docker.com | sh

fi

###############################################################################
# Docker Service
###############################################################################

systemctl enable docker
systemctl start docker

systemctl is-active docker >/dev/null \
    || die "Docker failed to start."

ok "Docker service running."

###############################################################################
# Docker Compose
###############################################################################

if docker compose version >/dev/null 2>&1; then

    ok "Docker Compose installed."

else

    info "Installing Docker Compose..."

    apt-get install -y docker-compose-plugin

fi

###############################################################################
# NVIDIA Toolkit Repository
###############################################################################

if ! command -v nvidia-container-runtime >/dev/null 2>&1; then

    info "Installing NVIDIA Container Toolkit..."

    mkdir -p /usr/share/keyrings

    curl -fsSL \
      https://nvidia.github.io/libnvidia-container/gpgkey \
      | gpg --dearmor \
      -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    distribution=$(. /etc/os-release;echo ${ID}${VERSION_ID})

    curl -fsSL \
      "https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list" \
      | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' \
      > /etc/apt/sources.list.d/nvidia-container-toolkit.list || {

        info "Falling back to stable repository..."

        curl -fsSL \
          https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
          | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' \
          > /etc/apt/sources.list.d/nvidia-container-toolkit.list
      }

    apt-get update

    apt-get install -y nvidia-container-toolkit

fi

###############################################################################
# Verify Toolkit
###############################################################################

command -v nvidia-container-runtime >/dev/null \
    || die "nvidia-container-runtime missing."

command -v nvidia-ctk >/dev/null \
    || die "nvidia-ctk missing."

ok "NVIDIA Toolkit installed."

###############################################################################
# Configure Runtime
###############################################################################

info "Configuring Docker runtime..."

nvidia-ctk runtime configure --runtime=docker

systemctl restart docker

sleep 3

docker info >/dev/null \
    || die "Docker failed after restart."

###############################################################################
# Verify Runtime Registration
###############################################################################

docker info | grep -qi nvidia \
    || die "Docker NVIDIA runtime not registered."

ok "Docker runtime configured."

###############################################################################
# Validate GPU Containers
###############################################################################

info "Validating GPU containers..."

docker pull nvidia/cuda:12.4.1-base-ubuntu22.04

docker run --rm \
    --gpus all \
    nvidia/cuda:12.4.1-base-ubuntu22.04 \
    nvidia-smi >/dev/null \
    || die "GPU container validation failed."

ok "GPU containers working."

###############################################################################
# Summary
###############################################################################

echo
echo "=========================================================="
echo " Atlas Nexus Host Installation Complete"
echo "=========================================================="
echo
echo "Next steps:"
echo
echo "  make host-check"
echo "  make storage-init"
echo "  make vllm-up"
echo
echo "=========================================================="