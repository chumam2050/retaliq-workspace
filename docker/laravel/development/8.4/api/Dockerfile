FROM choerul/base-php:8.4

ARG USER_ID=1000
ARG GROUP_ID=1000

# remap www-data UID/GID to 1000 (matches host dev user)
# so files created inside the container are editable from the host.
RUN groupmod -g $GROUP_ID www-data && \
    usermod -u $USER_ID www-data

# Copy PHP and nginx config
COPY php.ini $PHP_INI_DIR/conf.d/99-custom.ini
COPY opcache.ini $PHP_INI_DIR/conf.d/opcache.ini
COPY php-umask.php $PHP_INI_DIR/php-umask.php
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create log dir for supervisor
RUN mkdir -p /var/log/supervisor

WORKDIR /var/www/html

RUN git config --global --add safe.directory /var/www/html

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=5s --start-period=300s --retries=3 \
    CMD test -f /tmp/.ready && curl -f http://localhost/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
