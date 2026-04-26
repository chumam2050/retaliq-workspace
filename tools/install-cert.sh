#!/bin/bash
set -e

# Configuration
CONTAINER_NAME="caddy"
# Caddy stores its root CA in this path inside the container by default
CERT_PATH_IN_CONTAINER="/data/caddy/pki/authorities/local/root.crt"
HOST_CERT_DIR="/usr/local/share/ca-certificates"
HOST_CERT_NAME="caddy-root.crt"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 1. Check Root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)."
    exit 1
fi

# 2. Check Container
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Caddy container is not running. Start services first."
    exit 1
fi

log "Extracting Caddy Root CA..."
docker cp "${CONTAINER_NAME}:${CERT_PATH_IN_CONTAINER}" "/tmp/${HOST_CERT_NAME}"

# 3. Install to System
if [ -f "/tmp/${HOST_CERT_NAME}" ]; then
    log "Installing to system trust store..."
    cp "/tmp/${HOST_CERT_NAME}" "${HOST_CERT_DIR}/${HOST_CERT_NAME}"
    chmod 644 "${HOST_CERT_DIR}/${HOST_CERT_NAME}"
    update-ca-certificates
    rm "/tmp/${HOST_CERT_NAME}"
    log "Certificate installed successfully."
    
    echo ""
    echo "Important: Browsers (Chrome/Firefox) manage their own trust stores."
    echo "If you still see warnings, import '${HOST_CERT_DIR}/${HOST_CERT_NAME}' manually in your browser settings."
else
    error "Failed to extract certificate. Is Caddy running and generated a root CA yet?"
fi
