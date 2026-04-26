#!/bin/bash
# Caddy WAF Management Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if Caddy container is running
check_caddy() {
    if ! docker ps | grep -q "caddy"; then
        error "Caddy container is not running"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
Caddy WAF Management Script

USAGE:
    ./waf-manage.sh [COMMAND] [OPTIONS]

COMMANDS:
    status          Show current WAF status and configuration
    logs            Tail WAF logs
    stats           Show WAF statistics (blocks, top IPs, rules)
    test            Run WAF test suite
    reload          Reload Caddy configuration
    validate        Validate Caddyfile
    switch ENV      Switch between production/staging/development
    whitelist IP    Add IP to whitelist
    blacklist IP    Add IP to blacklist
    help            Show this help message

EXAMPLES:
    ./waf-manage.sh status
    ./waf-manage.sh logs
    ./waf-manage.sh stats
    ./waf-manage.sh switch production
    ./waf-manage.sh switch staging
    ./waf-manage.sh whitelist 203.0.113.5
    ./waf-manage.sh test

EOF
}

# Show WAF status
show_status() {
    info "Checking Caddy WAF status..."
    echo ""
    
    # Check environment
    ENV=$(grep "^RETALIQ_ENV=" "$SERVICE_DIR/.env" | cut -d'=' -f2)
    echo "Environment: ${ENV:-development}"
    
    # Check if Caddy is running
    if docker ps | grep -q "caddy"; then
        success "Caddy container is running"
        
        # Show active Caddyfile
        ACTIVE_CADDYFILE=$(docker exec caddy sh -c 'ls -la /etc/caddy/Caddyfile 2>/dev/null || echo "Not found"')
        echo "Active Caddyfile: $ACTIVE_CADDYFILE"
        
        # Show WAF status
        if [ "$ENV" = "production" ]; then
            success "WAF is ENABLED (production mode)"
            echo ""
            echo "WAF Configuration:"
            echo "  - Mode: block"
            echo "  - Anomaly Threshold: 10"
            echo "  - TLS: Let's Encrypt (automatic)"
            echo "  - Rule File: /etc/caddy/waf/rules.json"
            echo "  - IP Blacklist: /etc/caddy/waf/ip_blacklist.txt"
            echo "  - DNS Blacklist: /etc/caddy/waf/dns_blacklist.txt"
            echo "  - Log File: /var/log/caddy/waf.log"
        elif [ "$ENV" = "staging" ]; then
            success "WAF is ENABLED (staging mode)"
            echo ""
            echo "WAF Configuration:"
            echo "  - Mode: block"
            echo "  - Anomaly Threshold: 10"
            echo "  - TLS: Local certificates"
            echo "  - Rule File: /etc/caddy/waf/rules.json"
            echo "  - IP Blacklist: /etc/caddy/waf/ip_blacklist.txt"
            echo "  - DNS Blacklist: /etc/caddy/waf/dns_blacklist.txt"
            echo "  - Log File: /var/log/caddy/waf.log"
        else
            success "WAF is ENABLED (development mode)"
            echo ""
            echo "WAF Configuration:"
            echo "  - Mode: block"
            echo "  - Anomaly Threshold: 12"
            echo "  - TLS: Local certificates"
            echo "  - Rule File: /etc/caddy/waf/rules.json"
            echo "  - IP Blacklist: /etc/caddy/waf/ip_blacklist.txt"
            echo "  - DNS Blacklist: /etc/caddy/waf/dns_blacklist.txt"
            echo "  - Log File: /var/log/caddy/waf.log"
        fi
    else
        error "Caddy container is not running"
    fi
}

# Tail WAF logs
tail_logs() {
    check_caddy
    
    ENV=$(grep "^RETALIQ_ENV=" "$SERVICE_DIR/.env" | cut -d'=' -f2)
    
    if [ "$ENV" != "production" ] && [ "$ENV" != "staging" ] && [ "$ENV" != "development" ]; then
        warning "WAF logs not available in current mode"
        echo "Current mode: ${ENV:-development}"
        exit 1
    fi
    
    info "Tailing WAF logs (Ctrl+C to exit)..."
    docker exec caddy tail -f /var/log/caddy/waf.log
}

# Show WAF statistics
show_stats() {
    check_caddy
    
    ENV=$(grep "^RETALIQ_ENV=" "$SERVICE_DIR/.env" | cut -d'=' -f2)
    
    if [ "$ENV" != "production" ] && [ "$ENV" != "staging" ] && [ "$ENV" != "development" ]; then
        warning "WAF stats not available in current mode"
        exit 0
    fi
    
    info "Generating WAF statistics..."
    echo ""
    
    # Total blocks
    TOTAL_BLOCKS=$(docker exec caddy sh -c 'grep -Ei -c "blocked|block" /var/log/caddy/waf.log 2>/dev/null || echo 0')
    echo "Total Blocked Requests: $TOTAL_BLOCKS"
    echo ""
    
    # Blocks today
    TODAY=$(date +%Y-%m-%d)
    BLOCKS_TODAY=$(docker exec caddy sh -c "grep '$TODAY' /var/log/caddy/waf.log 2>/dev/null | grep -Ei -c 'blocked|block' || echo 0")
    echo "Blocked Today: $BLOCKS_TODAY"
    echo ""
    
    # Top blocked IPs
    echo "Top 10 Blocked IPs:"
    docker exec caddy sh -c 'grep -Ei "blocked|block" /var/log/caddy/waf.log 2>/dev/null | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort | uniq -c | sort -rn | head -10' || echo "No data"
    echo ""
    
    # Most triggered rules
    echo "Most Triggered Rules:"
    docker exec caddy sh -c 'grep -Eo "\"id\"\s*:\s*\"[^\"]+\"" /var/log/caddy/waf.log 2>/dev/null | sort | uniq -c | sort -rn | head -10' || echo "No data"
    echo ""
    
    # Recent blocks
    echo "Last 5 Blocked Requests:"
    docker exec caddy sh -c 'grep -Ei "blocked|block" /var/log/caddy/waf.log 2>/dev/null | tail -5' || echo "No data"
}

# Test WAF
test_waf() {
    check_caddy
    
    ENV=$(grep "^RETALIQ_ENV=" "$SERVICE_DIR/.env" | cut -d'=' -f2)
    DOMAIN=$(grep "^DOMAIN_NAME=" "$SERVICE_DIR/.env" | cut -d'=' -f2)
    
    if [ "$ENV" != "production" ] && [ "$ENV" != "staging" ] && [ "$ENV" != "development" ]; then
        warning "WAF is only active in production/staging/development mode"
        info "Switch to production, staging, or development mode to test WAF"
        exit 0
    fi
    
    info "Running WAF test suite against https://$DOMAIN"
    echo ""
    
    # Test 1: Normal request (should pass)
    echo -n "Test 1: Normal request... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "200" ]; then
        success "PASS (HTTP $RESPONSE)"
    else
        warning "Unexpected response: HTTP $RESPONSE"
    fi
    
    # Test 2: SQL injection (should block)
    echo -n "Test 2: SQL injection... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/?id=1' OR '1'='1" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "403" ]; then
        success "BLOCKED (HTTP $RESPONSE)"
    else
        error "NOT BLOCKED (HTTP $RESPONSE)"
    fi
    
    # Test 3: XSS attempt (should block)
    echo -n "Test 3: XSS attempt... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/?search=<script>alert('xss')</script>" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "403" ]; then
        success "BLOCKED (HTTP $RESPONSE)"
    else
        error "NOT BLOCKED (HTTP $RESPONSE)"
    fi
    
    # Test 4: Path traversal (should block)
    echo -n "Test 4: Path traversal... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/../../etc/passwd" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "403" ]; then
        success "BLOCKED (HTTP $RESPONSE)"
    else
        error "NOT BLOCKED (HTTP $RESPONSE)"
    fi
    
    # Test 5: Scanner detection (should block)
    echo -n "Test 5: Scanner detection... "
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -A "sqlmap/1.0" "https://$DOMAIN/" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "403" ]; then
        success "BLOCKED (HTTP $RESPONSE)"
    else
        error "NOT BLOCKED (HTTP $RESPONSE)"
    fi
    
    echo ""
    info "Test complete! Check WAF logs for details:"
    echo "docker exec caddy tail /var/log/caddy/waf.log"
}

# Reload Caddy configuration
reload_caddy() {
    check_caddy
    
    info "Reloading Caddy configuration..."
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile
    success "Configuration reloaded"
}

# Validate Caddyfile
validate_config() {
    check_caddy
    
    info "Validating Caddyfile..."
    if docker exec caddy caddy validate --config /etc/caddy/Caddyfile; then
        success "Caddyfile is valid"
    else
        error "Caddyfile validation failed"
        exit 1
    fi
}

# Switch environment
switch_env() {
    local NEW_ENV=$1
    
    if [ -z "$NEW_ENV" ]; then
        error "Please specify environment (production, staging, or development)"
        exit 1
    fi
    
    if [ "$NEW_ENV" != "production" ] && [ "$NEW_ENV" != "staging" ] && [ "$NEW_ENV" != "development" ]; then
        error "Invalid environment. Use 'production', 'staging', or 'development'"
        exit 1
    fi
    
    info "Switching to $NEW_ENV mode..."
    
    # Update .env file
    if grep -q "^RETALIQ_ENV=" "$SERVICE_DIR/.env"; then
        sed -i "s/^RETALIQ_ENV=.*/RETALIQ_ENV=$NEW_ENV/" "$SERVICE_DIR/.env"
    else
        echo "RETALIQ_ENV=$NEW_ENV" >> "$SERVICE_DIR/.env"
    fi
    
    success "Updated .env file"
    
    # Rebuild and recreate Caddy so latest entrypoint/config changes are applied.
    info "Rebuilding and recreating Caddy container..."
    cd "$SERVICE_DIR" && docker compose up -d --build --force-recreate --no-deps caddy
    
    success "Switched to $NEW_ENV mode"
    
    if [ "$NEW_ENV" = "production" ]; then
        warning "WAF is now ENABLED with Let's Encrypt certificates"
        echo "Monitor logs: docker exec caddy tail -f /var/log/caddy/waf.log"
    elif [ "$NEW_ENV" = "staging" ]; then
        warning "WAF is now ENABLED with local certificates (staging)"
        echo "Monitor logs: docker exec caddy tail -f /var/log/caddy/waf.log"
    else
        warning "WAF is now ENABLED with local certificates"
        echo "Monitor logs: docker exec caddy tail -f /var/log/caddy/waf.log"
    fi
}

# Add IP to whitelist
whitelist_ip() {
    local IP=$1
    
    if [ -z "$IP" ]; then
        error "Please specify an IP address"
        exit 1
    fi
    
    warning "Whitelist khusus belum terpasang di caddy-waf config saat ini."
    info "Jika $IP ada di blacklist, entry akan dihapus dari /services/caddy/waf/ip_blacklist.txt"

    if [ -f "$SCRIPT_DIR/waf/ip_blacklist.txt" ]; then
        sed -i "/^$IP$/d" "$SCRIPT_DIR/waf/ip_blacklist.txt"
        success "IP $IP dihapus dari blacklist (jika ada)"
    else
        warning "File blacklist belum ada: $SCRIPT_DIR/waf/ip_blacklist.txt"
    fi

    warning "Reload Caddy untuk menerapkan perubahan: docker compose restart caddy"
}

# Add IP to blacklist
blacklist_ip() {
    local IP=$1
    
    if [ -z "$IP" ]; then
        error "Please specify an IP address"
        exit 1
    fi
    
    info "Adding $IP to WAF blacklist..."

    if [ ! -f "$SCRIPT_DIR/waf/ip_blacklist.txt" ]; then
        touch "$SCRIPT_DIR/waf/ip_blacklist.txt"
    fi

    if grep -qx "$IP" "$SCRIPT_DIR/waf/ip_blacklist.txt"; then
        warning "IP $IP sudah ada di blacklist"
    else
        echo "$IP" >> "$SCRIPT_DIR/waf/ip_blacklist.txt"
        success "IP $IP added to blacklist"
    fi

    warning "Restart Caddy to apply changes: docker compose restart caddy"
}

# Main script
case "${1:-help}" in
    status)
        show_status
        ;;
    logs)
        tail_logs
        ;;
    stats)
        show_stats
        ;;
    test)
        test_waf
        ;;
    reload)
        reload_caddy
        ;;
    validate)
        validate_config
        ;;
    switch)
        switch_env "$2"
        ;;
    whitelist)
        whitelist_ip "$2"
        ;;
    blacklist)
        blacklist_ip "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
