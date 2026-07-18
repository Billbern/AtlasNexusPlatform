#!/usr/bin/env bash

###############################################################################
# Atlas Nexus - Host Installer
#
# Purpose:
#   Prepare a fresh Ubuntu host for Atlas Nexus.
#
# This script is idempotent.
###############################################################################

set -euo pipefail

###############################################################################
# Root Check
###############################################################################

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo."
    exit 1
fi

echo
echo "========================================================"
echo "      Atlas Nexus - Host Installation"
echo "========================================================"
echo

###############################################################################
# Package Index
###############################################################################

echo "[INFO] Updating package index..."
apt-get update

###############################################################################
# Base Packages
###############################################################################

BASE_PACKAGES=(
    git
    curl
    wget
    unzip
    ca-certificates
    gnupg
    lsb-release
    software-properties-common
)

for package in "${BASE_PACKAGES[@]}"; do

    if dpkg -s "$package" >/dev/null 2>&1; then
        echo "[OK] $package already installed."
    else
        echo "[INSTALL] $package"
        apt-get install -y "$package"
    fi

done

###############################################################################
# Docker
###############################################################################

if command -v docker >/dev/null 2>&1; then

    echo "[OK] Docker already installed."

else

    echo "[INSTALL] Docker"

    curl -fsSL https://get.docker.com | sh

fi

###############################################################################
# Docker Service
###############################################################################

if systemctl is-enabled docker >/dev/null 2>&1; then
    echo "[OK] Docker service enabled."
else
    systemctl enable docker
fi

if systemctl is-active docker >/dev/null 2>&1; then
    echo "[OK] Docker service running."
else
    systemctl start docker
fi

###############################################################################
# Docker Compose Plugin
###############################################################################

if docker compose version >/dev/null 2>&1; then

    echo "[OK] Docker Compose already installed."

else

    echo "[INSTALL] Docker Compose Plugin"

    apt-get install -y docker-compose-plugin

fi

###############################################################################
# NVIDIA Container Toolkit
###############################################################################

if dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then

    echo "[OK] NVIDIA Container Toolkit already installed."

else

    echo "[INSTALL] NVIDIA Container Toolkit"

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
        | gpg --dearmor \
        -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    curl -s -L \
        https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        > /etc/apt/sources.list.d/nvidia-container-toolkit.list

    apt-get update

    apt-get install -y nvidia-container-toolkit

    nvidia-ctk runtime configure --runtime=docker

    systemctl restart docker

fi

###############################################################################
# Complete
###############################################################################

echo
echo "========================================================"
echo "Host installation complete."
echo "Run ./scripts/host-check.sh to verify the installation."
echo "========================================================"