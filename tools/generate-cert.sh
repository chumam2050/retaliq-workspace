#!/bin/bash
set -e

# Configuration
CERTS_DIR="./services/caddy/certs"
ROOT_CA_NAME="Retaliq-Local-CA"
DOMAIN_NAME=${1:-"localhost"} # First argument or default to localhost
DAYS_VALID=365

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "$CERTS_DIR"

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 1. Generate Root CA (if not exists)
if [[ ! -f "$CERTS_DIR/rootCA.key" || ! -f "$CERTS_DIR/rootCA.pem" ]]; then
    log "Generating Root CA..."
    openssl genrsa -out "$CERTS_DIR/rootCA.key" 4096
    openssl req -x509 -new -nodes -key "$CERTS_DIR/rootCA.key" -sha256 -days 3650 \
        -out "$CERTS_DIR/rootCA.pem" \
        -subj "/C=US/ST=Dev/L=Local/O=Retaliq Dev/CN=$ROOT_CA_NAME"
    success "Root CA generated at $CERTS_DIR/rootCA.pem"
    echo "⚠️  Please install '$CERTS_DIR/rootCA.pem' into your OS/Browser Trusted Root Store."
else
    log "Existing Root CA found."
fi

# 2. Generate Domain Certificate
log "Generating certificate for: $DOMAIN_NAME"

# Create config for SAN (Subject Alternative Name)
cat > "$CERTS_DIR/$DOMAIN_NAME.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = US
ST = Dev
L = Local
O = Retaliq Dev
CN = $DOMAIN_NAME

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN_NAME
DNS.2 = *.$DOMAIN_NAME
IP.1 = 127.0.0.1
EOF

# Generate Private Key
openssl genrsa -out "$CERTS_DIR/$DOMAIN_NAME.key" 2048

# Generate CSR (Certificate Signing Request)
openssl req -new -key "$CERTS_DIR/$DOMAIN_NAME.key" \
    -out "$CERTS_DIR/$DOMAIN_NAME.csr" \
    -config "$CERTS_DIR/$DOMAIN_NAME.cnf"

# Sign CSR with Root CA
openssl x509 -req -in "$CERTS_DIR/$DOMAIN_NAME.csr" \
    -CA "$CERTS_DIR/rootCA.pem" \
    -CAkey "$CERTS_DIR/rootCA.key" \
    -CAcreateserial \
    -out "$CERTS_DIR/$DOMAIN_NAME.crt" \
    -days "$DAYS_VALID" \
    -sha256 \
    -extfile "$CERTS_DIR/$DOMAIN_NAME.cnf" \
    -extensions req_ext

# Cleanup temp files
rm "$CERTS_DIR/$DOMAIN_NAME.csr" "$CERTS_DIR/$DOMAIN_NAME.cnf"

success "Certificate created:"
echo " - Key: $CERTS_DIR/$DOMAIN_NAME.key"
echo " - Cert: $CERTS_DIR/$DOMAIN_NAME.crt"
echo ""
echo "To use in Caddy, update Caddyfile:"
echo "$DOMAIN_NAME {"
echo "    tls /etc/caddy/certs/$DOMAIN_NAME.crt /etc/caddy/certs/$DOMAIN_NAME.key"
echo "}"
