# Stage 1: Copy application code
FROM choerul/base-laravel:8.4-alpine

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY --chown=www-data:www-data . /var/www/html

# Copy Nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/http.d/default.conf

# Copy Supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Ensure production image never carries Vite hot mode marker.
RUN rm -f public/hot

# Install PHP dependencies (production only)
RUN composer install --no-dev --no-scripts --no-interaction --prefer-dist --optimize-autoloader

# Remove stale Laravel package manifests from dev environment before running artisan.
RUN rm -f bootstrap/cache/packages.php bootstrap/cache/services.php

# Generate wayfinder
RUN php artisan wayfinder:generate

# Build frontend assets
RUN npm install && npm run build:ssr && npm run build

# Copy custom PHP configuration after dependency install.
COPY docker/php.ini $PHP_INI_DIR/conf.d/99-custom.ini
COPY docker/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

# Create necessary directories and set permissions
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    storage/nginx/client_body \
    storage/nginx/proxy \
    storage/nginx/fastcgi \
    storage/nginx/uwsgi \
    storage/nginx/scgi \
    bootstrap/cache \
    /var/log/supervisor \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Remove Dockerfile and related files to keep production image clean
RUN rm -rf docker

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start via entrypoint
ENTRYPOINT ["/entrypoint.sh"]
