#!/bin/bash
set -e

# Function buat bikin DB + user
create_database_and_user() {
    local db=$1
    local user=$2
    local password=$3

    echo "Creating user '$user' and database '$db'..."

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE USER $user WITH PASSWORD '$password';
        CREATE DATABASE $db OWNER $user;
        GRANT ALL PRIVILEGES ON DATABASE $db TO $user;

        -- Pastikan user juga bisa CREATE di schema public (Postgres 15+ default-nya gak boleh)
        \c $db
        GRANT ALL ON SCHEMA public TO $user;
EOSQL
}

# Bikin DB untuk App 1
if [ -n "$APP1_DB" ] && [ -n "$APP1_USER" ] && [ -n "$APP1_PASSWORD" ]; then
    create_database_and_user "$APP1_DB" "$APP1_USER" "$APP1_PASSWORD"
fi

echo "All databases initialized."
