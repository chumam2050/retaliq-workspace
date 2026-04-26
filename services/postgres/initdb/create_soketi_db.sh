#!/bin/bash
set -e

# Create soketi database if it's not the default POSTGRES_DB
# The user passed in POSTGRES_DB (usually defaults to POSTGRES_USER if unset)
if [ "$POSTGRES_DB" != "soketi" ]; then
    echo "Creating database: soketi"
    # Try to create DB, ignore if exists (though init scripts run on empty data dir, so normally it wouldn't exist unless POSTGRES_DB is soketi)
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE soketi" || true
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "GRANT ALL PRIVILEGES ON DATABASE soketi TO $POSTGRES_USER"
fi

echo "Initializing soketi tables in database: soketi"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "soketi" <<-EOSQL
    CREATE TABLE IF NOT EXISTS apps (
        id varchar(255) NOT NULL,
        key varchar(255) NOT NULL,
        secret varchar(255) NOT NULL,
        max_connections integer NOT NULL,
        enable_client_messages boolean NOT NULL,
        enabled boolean NOT NULL,
        max_backend_events_per_sec integer NOT NULL,
        max_client_events_per_sec integer NOT NULL,
        max_read_req_per_sec integer NOT NULL,
        webhooks json,
        max_presence_members_per_channel integer NULL,
        max_presence_member_size_in_kb integer NULL,
        max_channel_name_length integer NULL,
        max_event_channels_at_once integer NULL,
        max_event_name_length integer NULL,
        max_event_payload_in_kb integer NULL,
        max_event_batch_size integer NULL,
        enable_user_authentication boolean NOT NULL,
        PRIMARY KEY (id)
    );
EOSQL


