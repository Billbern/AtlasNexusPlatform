#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STORAGE_DIR="${ROOT_DIR}/storage"

echo
echo "=========================================================="
echo "        Atlas Nexus - Storage Initialization"
echo "=========================================================="
echo

echo -e "${BLUE}[INFO]${NC} Creating storage directories..."

mkdir -p \
    "${STORAGE_DIR}/models" \
    "${STORAGE_DIR}/huggingface" \
    "${STORAGE_DIR}/vllm/cache" \
    "${STORAGE_DIR}/vllm/logs" \
    "${STORAGE_DIR}/litellm/config" \
    "${STORAGE_DIR}/litellm/logs" \
    "${STORAGE_DIR}/open-webui/data" \
    "${STORAGE_DIR}/open-webui/logs" \
    "${STORAGE_DIR}/postgres" \
    "${STORAGE_DIR}/redis" \
    "${STORAGE_DIR}/monitoring/prometheus" \
    "${STORAGE_DIR}/monitoring/grafana" \
    "${STORAGE_DIR}/backups"

echo -e "${BLUE}[INFO]${NC} Setting directory permissions..."

chmod -R 755 "${STORAGE_DIR}"

echo -e "${GREEN}[PASS]${NC} Storage initialized successfully."

echo
echo "Storage Root:"
echo "  ${STORAGE_DIR}"
echo
