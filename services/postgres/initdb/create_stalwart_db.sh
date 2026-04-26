#!/bin/bash
set -e

# Create stalwart database if it's not the default POSTGRES_DB
if [ "$POSTGRES_DB" != "stalwart" ]; then
    echo "Creating database: stalwart"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE stalwart" || true
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "GRANT ALL PRIVILEGES ON DATABASE stalwart TO $POSTGRES_USER"
fi

# Stalwart handles its own schema migrations, so we just ensure the DB exists.
echo "Stalwart database initialization complete."
