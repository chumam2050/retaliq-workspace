#!/bin/sh
# Security Hardening Verification Script
# Run this inside the container to verify security configurations

set -e

echo "==================================="
echo "PHP Production Security Check"
echo "==================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo "${GREEN}✓${NC} $1"
}

check_fail() {
    echo "${RED}✗${NC} $1"
}

check_warn() {
    echo "${YELLOW}⚠${NC} $1"
}

echo "1. PHP Configuration Checks"
echo "-----------------------------------"

# Check disabled functions
DISABLED_FUNCS=$(php -r "echo ini_get('disable_functions');")
if echo "$DISABLED_FUNCS" | grep -q "exec"; then
    check_pass "Dangerous functions are disabled"
else
    check_fail "Dangerous functions NOT disabled"
fi

# Check expose_php
EXPOSE_PHP=$(php -r "echo ini_get('expose_php');")
if [ "$EXPOSE_PHP" = "" ] || [ "$EXPOSE_PHP" = "0" ]; then
    check_pass "PHP version is hidden (expose_php=Off)"
else
    check_warn "PHP version is exposed (expose_php=On)"
fi

# Check display_errors
DISPLAY_ERRORS=$(php -r "echo ini_get('display_errors');")
if [ "$DISPLAY_ERRORS" = "" ] || [ "$DISPLAY_ERRORS" = "0" ]; then
    check_pass "Error display is disabled"
else
    check_fail "Error display is ENABLED - not safe for production!"
fi

# Check open_basedir
OPEN_BASEDIR=$(php -r "echo ini_get('open_basedir');")
if [ -n "$OPEN_BASEDIR" ]; then
    check_pass "open_basedir restriction is set: $OPEN_BASEDIR"
else
    check_warn "open_basedir is not restricted"
fi

# Check allow_url_include
ALLOW_URL_INCLUDE=$(php -r "echo ini_get('allow_url_include');")
if [ "$ALLOW_URL_INCLUDE" = "" ] || [ "$ALLOW_URL_INCLUDE" = "0" ]; then
    check_pass "Remote file inclusion is disabled"
else
    check_fail "Remote file inclusion is ENABLED - security risk!"
fi

# Check session security
SESSION_HTTPONLY=$(php -r "echo ini_get('session.cookie_httponly');")
SESSION_SECURE=$(php -r "echo ini_get('session.cookie_secure');")
SESSION_SAMESITE=$(php -r "echo ini_get('session.cookie_samesite');")

if [ "$SESSION_HTTPONLY" = "1" ]; then
    check_pass "Session cookies are HTTPOnly"
else
    check_fail "Session cookies are NOT HTTPOnly"
fi

if [ "$SESSION_SECURE" = "1" ]; then
    check_pass "Session cookies are Secure"
else
    check_warn "Session cookies are NOT Secure (OK if behind HTTPS proxy)"
fi

if [ "$SESSION_SAMESITE" = "Strict" ] || [ "$SESSION_SAMESITE" = "Lax" ]; then
    check_pass "Session SameSite is set: $SESSION_SAMESITE"
else
    check_warn "Session SameSite is not set"
fi

echo ""
echo "2. OPcache Configuration Checks"
echo "-----------------------------------"

# Check if OPcache is enabled
OPCACHE_ENABLED=$(php -r "echo ini_get('opcache.enable');")
if [ "$OPCACHE_ENABLED" = "1" ]; then
    check_pass "OPcache is enabled"
    
    # Check validate_timestamps (should be 0 in production)
    VALIDATE_TS=$(php -r "echo ini_get('opcache.validate_timestamps');")
    if [ "$VALIDATE_TS" = "0" ]; then
        check_pass "OPcache timestamp validation disabled (production mode)"
    else
        check_warn "OPcache timestamp validation is enabled (development mode)"
    fi
    
    # Check permission validation
    VALIDATE_PERM=$(php -r "echo ini_get('opcache.validate_permission');")
    if [ "$VALIDATE_PERM" = "1" ]; then
        check_pass "OPcache permission validation enabled"
    else
        check_warn "OPcache permission validation disabled"
    fi
else
    check_fail "OPcache is DISABLED - performance issue!"
fi

echo ""
echo "3. File Permissions Checks"
echo "-----------------------------------"

# Check .env permissions
if [ -f "/var/www/html/.env" ]; then
    ENV_PERMS=$(stat -c %a /var/www/html/.env 2>/dev/null || stat -f %Lp /var/www/html/.env 2>/dev/null)
    if [ "$ENV_PERMS" = "640" ] || [ "$ENV_PERMS" = "600" ]; then
        check_pass ".env file has secure permissions: $ENV_PERMS"
    else
        check_warn ".env file permissions: $ENV_PERMS (should be 640 or 600)"
    fi
else
    check_warn ".env file not found"
fi

# Check storage permissions
if [ -d "/var/www/html/storage" ]; then
    STORAGE_OWNER=$(stat -c %U /var/www/html/storage 2>/dev/null || stat -f %Su /var/www/html/storage 2>/dev/null)
    if [ "$STORAGE_OWNER" = "www-data" ]; then
        check_pass "Storage directory owned by www-data"
    else
        check_fail "Storage directory NOT owned by www-data: $STORAGE_OWNER"
    fi
fi

echo ""
echo "4. Laravel Configuration Checks"
echo "-----------------------------------"

# Check APP_DEBUG
if [ -f "/var/www/html/.env" ]; then
    APP_DEBUG=$(grep "^APP_DEBUG=" /var/www/html/.env | cut -d'=' -f2)
    if [ "$APP_DEBUG" = "false" ] || [ "$APP_DEBUG" = "False" ] || [ "$APP_DEBUG" = "FALSE" ]; then
        check_pass "APP_DEBUG is disabled"
    else
        check_fail "APP_DEBUG is ENABLED - not safe for production!"
    fi
    
    APP_ENV=$(grep "^APP_ENV=" /var/www/html/.env | cut -d'=' -f2)
    if [ "$APP_ENV" = "production" ]; then
        check_pass "APP_ENV is set to production"
    else
        check_warn "APP_ENV is not 'production': $APP_ENV"
    fi
fi

# Check for cached configs
if [ -f "/var/www/html/bootstrap/cache/config.php" ]; then
    check_pass "Configuration is cached"
else
    check_warn "Configuration is not cached (run: php artisan config:cache)"
fi

if [ -f "/var/www/html/bootstrap/cache/routes-v7.php" ]; then
    check_pass "Routes are cached"
else
    check_warn "Routes are not cached (run: php artisan route:cache)"
fi

echo ""
echo "5. Web Server Accessibility Checks"
echo "-----------------------------------"

# Check if sensitive files are protected
check_protected() {
    local path=$1
    if [ -f "$path" ] || [ -d "$path" ]; then
        check_warn "$path exists (should be protected by nginx)"
    fi
}

check_protected "/var/www/html/.env"
check_protected "/var/www/html/composer.json"
check_protected "/var/www/html/phpunit.xml"

echo ""
echo "6. Process Security Checks"
echo "-----------------------------------"

# Check which user is running PHP-FPM
PHP_FPM_USER=$(ps aux | grep php-fpm | grep -v grep | grep -v "php-fpm: master" | head -1 | awk '{print $1}')
if [ "$PHP_FPM_USER" = "www-data" ]; then
    check_pass "PHP-FPM running as www-data"
else
    check_warn "PHP-FPM running as: $PHP_FPM_USER"
fi

# Check which user is running Nginx
NGINX_USER=$(ps aux | grep nginx | grep -v grep | grep -v "nginx: master" | head -1 | awk '{print $1}')
if [ "$NGINX_USER" = "www-data" ]; then
    check_pass "Nginx worker running as www-data"
else
    check_warn "Nginx worker running as: $NGINX_USER"
fi

echo ""
echo "==================================="
echo "Security Check Complete"
echo "==================================="
echo ""
echo "Note: Some warnings are acceptable depending on your setup."
echo "Review the output and address any failures (✗) immediately."
echo ""
