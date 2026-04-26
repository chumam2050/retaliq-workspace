#!/bin/sh
# Caddy entrypoint script - selects Caddyfile based on environment

set -e

# Default to development if not set
ENV=${RETALIQ_ENV:-development}

# Determine which Caddyfile to use
if [ "$ENV" = "production" ]; then
    CADDYFILE="/etc/caddy/Caddyfile.production"
    echo "🔒 Starting Caddy in PRODUCTION mode"
    echo "   WAF: ENABLED (block mode)"
    echo "   Security Headers: enabled"
    echo "   TLS: Let's Encrypt (automatic)"
    echo "   Auto HTTPS: enabled"
elif [ "$ENV" = "staging" ]; then
    CADDYFILE="/etc/caddy/Caddyfile.staging"
    echo "🧪 Starting Caddy in STAGING mode"
    echo "   WAF: ENABLED (block mode)"
    echo "   Security Headers: enabled"
    echo "   TLS: Local certificates"
    echo "   Auto HTTPS: enabled"
else
    CADDYFILE="/etc/caddy/Caddyfile.development"
    echo "🔧 Starting Caddy in DEVELOPMENT mode"
    echo "   WAF: ENABLED (block mode)"
    echo "   Security Headers: enabled"
    echo "   TLS: Local certificates"
    echo "   Auto HTTPS: disabled"
fi

# Copy the appropriate Caddyfile
if [ -f "$CADDYFILE" ]; then
    cp "$CADDYFILE" /etc/caddy/Caddyfile
    echo "✓ Using Caddyfile: $CADDYFILE"
else
    echo "❌ ERROR: Caddyfile not found: $CADDYFILE"
    exit 1
fi

# Create necessary directories
mkdir -p /var/log/caddy
mkdir -p /etc/caddy/waf 2>/dev/null || true

# Set permissions (ignore errors for read-only mounts)
chmod 644 /etc/caddy/Caddyfile 2>/dev/null || true
chmod -R 755 /etc/caddy/waf 2>/dev/null || true

# Validate Caddyfile
echo "Validating Caddyfile..."
if caddy validate --config /etc/caddy/Caddyfile; then
    echo "✓ Caddyfile validation successful"
else
    echo "❌ ERROR: Caddyfile validation failed"
    exit 1
fi

# Display configuration summary
echo ""
echo "================================"
echo "Caddy Configuration Summary"
echo "================================"
echo "Environment: $ENV"
echo "Domain: ${DOMAIN_NAME:-localhost}"
echo "Config: /etc/caddy/Caddyfile"
echo "WAF: ENABLED"
if [ "$ENV" = "production" ] || [ "$ENV" = "staging" ]; then
    echo "WAF Rules: /etc/caddy/waf/rules.json"
else
    echo "WAF Rules: /etc/caddy/waf/rules-dev.json"
fi
echo "WAF IP Blacklist: /etc/caddy/waf/ip_blacklist.txt"
echo "WAF DNS Blacklist: /etc/caddy/waf/dns_blacklist.txt"
echo "WAF Log: /var/log/caddy/waf.log"
if [ "$ENV" = "production" ]; then
    echo "TLS: Let's Encrypt (automatic)"
elif [ "$ENV" = "staging" ]; then
    echo "TLS: Local certificates"
else
    echo "TLS: Local certificates"
fi
echo "================================"
echo ""

# Start Caddy
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
