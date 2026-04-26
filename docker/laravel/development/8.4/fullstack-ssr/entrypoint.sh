#!/bin/sh

set -e

# Set permissive umask: directories 775, files 664
umask 0002

USER_ID=1000
GROUP_ID=1000

# Change to the application directory
cd /var/www/html

# Create .env from example if missing
php -r "file_exists('.env') || copy('.env.example', '.env');";

# Give UID 1000 (host dev) full ownership of .env so artisan can write to it.
if [ -f .env ]; then
    chown $USER_ID:$GROUP_ID .env 2>/dev/null || true
    chmod 660 .env 2>/dev/null || true
fi

DEFAULT_APP_NAME='laravel'
APP_NAME="$DEFAULT_APP_NAME"

# Load APP_NAME from .env if it exists. (Only export APP_NAME to avoid malformed URI/env issues.)
if [ -f .env ]; then
    # Support quoted values
    env_app_name=$(grep -E '^APP_NAME=' .env | tail -n 1 | cut -d'=' -f2- | sed 's/^"\?//; s/"\?$//')
    if [ -n "$env_app_name" ]; then
        APP_NAME="$env_app_name"
    fi
fi

# If APP_NAME is set in the environment / .env, use it; otherwise use default
if [ -n "$APP_NAME" ]; then
    # Make APP_NAME safe for use in directory names
    APP_NAME=$(printf '%s' "$APP_NAME" | tr -c '[:alnum:]_.-' '_')
else
    APP_NAME="$DEFAULT_APP_NAME"
fi

TEMP_PATH="/tmp/$APP_NAME"

# Ensure TEMP_PATH exists for hash tracking
mkdir -p "$TEMP_PATH"

# Ensure storage and cache directories exist (volume mount wipes them)
mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    storage/app/public \
    storage/nginx/client_body \
    storage/nginx/proxy \
    storage/nginx/fastcgi \
    storage/nginx/uwsgi \
    storage/nginx/scgi \
    bootstrap/cache

chown -R $USER_ID:$GROUP_ID storage bootstrap/cache
chmod -R 775 storage/app/public storage/framework storage/logs storage/nginx bootstrap/cache

# Install PHP dependencies if vendor is missing or composer.lock changed
COMPOSER_HASH_FILE="$TEMP_PATH/.composer.lock.md5"
COMPOSER_HASH=$(md5sum composer.lock 2>/dev/null | cut -d' ' -f1)

COMPOSER_PROCESS_TIMEOUT=${COMPOSER_PROCESS_TIMEOUT:-2000} # seconds
COMPOSER_MAX_RETRIES=${COMPOSER_MAX_RETRIES:-2}

composer_install() {
    local attempt=1
    while [ "$attempt" -le "$COMPOSER_MAX_RETRIES" ]; do
        echo "[entrypoint] composer install attempt $attempt/$COMPOSER_MAX_RETRIES"
        COMPOSER_PROCESS_TIMEOUT="$COMPOSER_PROCESS_TIMEOUT" composer clear-cache >/dev/null 2>&1 || true
        if COMPOSER_PROCESS_TIMEOUT="$COMPOSER_PROCESS_TIMEOUT" composer install --no-interaction --prefer-dist --no-progress; then
            return 0
        fi

        if [ "$attempt" -lt "$COMPOSER_MAX_RETRIES" ]; then
            echo "[entrypoint] composer install failed, retrying in 5s..."
            sleep 5
        fi
        attempt=$((attempt + 1))
    done

    echo "[entrypoint] composer install failed after $COMPOSER_MAX_RETRIES attempts"
    return 1
}

if [ ! -d vendor ] || [ ! -f "$COMPOSER_HASH_FILE" ] || [ "$(cat $COMPOSER_HASH_FILE)" != "$COMPOSER_HASH" ]; then
    echo "[entrypoint] composer.lock changed or vendor/ missing, running composer install..."
    composer_install
    chown -R $USER_ID:$GROUP_ID vendor
    chmod -R 775 vendor
    echo "$COMPOSER_HASH" > "$COMPOSER_HASH_FILE"
fi

if [ ! -d /.composer ]; then
    mkdir /.composer
fi

chmod -R ugo+rw /.composer

# Install JS dependencies if node_modules is missing or package-lock.json changed
NPM_HASH_FILE="$TEMP_PATH/.package-lock.json.md5"
NPM_HASH=$(md5sum package-lock.json 2>/dev/null | cut -d' ' -f1)
if [ ! -d node_modules ] || [ ! -f "$NPM_HASH_FILE" ] || [ "$(cat $NPM_HASH_FILE)" != "$NPM_HASH" ]; then
    echo "[entrypoint] package-lock.json changed or node_modules/ missing, running npm install..."
    npm install
    chown -R $USER_ID:$GROUP_ID node_modules
    chmod -R 775 node_modules
    echo "$NPM_HASH" > "$NPM_HASH_FILE"
fi

# Generate app key if missing
php artisan key:generate

# Determine whether to run migrations and seeders (default: off)
MIGRATION=${RUN_MIGRATION:-false}
SEEDER=${RUN_SEEDER:-false}

if [ -f .env ]; then
    env_run_migration=$(grep -E '^RUN_MIGRATION=' .env | tail -n 1 | cut -d'=' -f2- | sed 's/^"\?//; s/"\?$//')
    env_run_seeder=$(grep -E '^RUN_SEEDER=' .env | tail -n 1 | cut -d'=' -f2- | sed 's/^"\?//; s/"\?$//')

    if [ -n "$env_run_migration" ]; then
        MIGRATION=$env_run_migration
    fi

    if [ -n "$env_run_seeder" ]; then
        SEEDER=$env_run_seeder
    fi
fi

run_bool() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        1|true|on|yes) return 0 ;;
        *) return 1 ;;
    esac
}

if run_bool "$MIGRATION"; then
    echo "[entrypoint] running database migrations"
    php artisan migrate:refresh --force
else
    echo "[entrypoint] skipping migrations (MIGRATION=false)"
fi

if run_bool "$SEEDER"; then
    echo "[entrypoint] running database seeders"
    php artisan db:seed --force
else
    echo "[entrypoint] skipping seeders (SEEDER=false)"
fi

# Clear all caches — never cache in development
php /var/www/html/artisan config:clear
php /var/www/html/artisan route:clear
php /var/www/html/artisan view:clear

npm run build:ssr 2>/dev/null || true

php /var/www/html/artisan storage:link 2>/dev/null || true

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf