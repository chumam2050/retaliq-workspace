FROM php:8.5-fpm-alpine

LABEL maintainer="Choerul Umam <dev@retaliq.cloud>"

# Install system dependencies
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    freetype-dev \
    libzip-dev \
    postgresql-dev \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    && apk add --no-cache \
    libpng \
    libjpeg-turbo \
    libwebp \
    freetype \
    libzip \
    zip \
    unzip \
    git \
    curl \
    nginx \
    supervisor \
    postgresql-libs \
    libxml2 \
    mysql-client \
    icu-libs \
    nodejs \
    npm \
    ffmpeg \
    imagemagick \
    ghostscript \
    bash \
    su-exec \
    shadow \
    python3

# Install PHP extensions
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath zip opcache xdebug redis intl

# Cleanup build dependencies
RUN apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*