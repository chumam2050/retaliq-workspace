#!/bin/sh
set -e

# Security: Ensure we're running as expected user
if [ "$(id -u)" -eq 0 ]; then
    echo "Running entrypoint as root (will spawn child processes as www-data)"
fi

# Ensure storage directories exist (may be wiped by volume mounts)
mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    storage/nginx/client_body \
    storage/nginx/proxy \
    storage/nginx/fastcgi \
    storage/nginx/uwsgi \
    storage/nginx/scgi \
    bootstrap/cache

# Set secure permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Secure sensitive files
chmod 640 .env 2>/dev/null || true
chmod 644 composer.json 2>/dev/null || true
chmod 644 composer.lock 2>/dev/null || true

# Protect critical directories
chmod -R 750 app config database routes 2>/dev/null || true

# Cache config with runtime .env values
php /var/www/html/artisan config:cache
php /var/www/html/artisan route:cache
php /var/www/html/artisan view:cache

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
