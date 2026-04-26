#!/bin/bash
set -e

# Hardcoded DB name for Roundcube
RC_DB="roundcubemail"
# Using the main Postgres user provided by env var POSTGRES_USER
RC_USER="$POSTGRES_USER"

echo "Creating database: $RC_DB with owner $RC_USER"

# Connect as POSTGRES_USER to the default "postgres" db
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    -- Create database if it doesn't exist, owned by the main user
    SELECT 'CREATE DATABASE $RC_DB OWNER $RC_USER'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$RC_DB')\gexec
EOSQL

# Grant permissions (though owner usually has them, it's safer to ensure schema access)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$RC_DB" <<-EOSQL
    -- Grant schema usage just in case
    GRANT ALL ON SCHEMA public TO $RC_USER;
EOSQL
