#!/bin/bash
set -e

# Create glitchtip database if it's not the default POSTGRES_DB
if [ "$POSTGRES_DB" != "glitchtip" ]; then
    echo "Creating database: glitchtip"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE glitchtip" || true
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "GRANT ALL PRIVILEGES ON DATABASE glitchtip TO $POSTGRES_USER"
fi

echo "GlitchTip database initialization complete."
