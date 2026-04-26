FROM php:8.4-fpm-alpine

LABEL maintainer="Choerul Umam <dev@retaliq.cloud>"

# Install system dependencies and build tools
RUN apk add --no-cache curl nginx supervisor nodejs npm

# Install the PHP extension installer
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Configure and install PHP extensions
RUN install-php-extensions @composer gd pdo_mysql pdo_pgsql exif pcntl bcmath zip intl redis

# Configure PHP for production
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Set working directory
WORKDIR /var/www/html