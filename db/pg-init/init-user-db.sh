#!/bin/bash
set -e

echo
echo "Setting up $DB_USER and Workshops databases..."
echo
psql -U "$POSTGRES_USER" -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
echo

for db in workshops_test workshops_development workshops_production
do
  echo "Setting up $db database..."
  psql -U "$POSTGRES_USER" -c "CREATE DATABASE $db OWNER=$DB_USER
    ENCODING 'UTF8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8'"

  psql -U "$POSTGRES_USER" -c "GRANT ALL PRIVILEGES ON DATABASE $db to $DB_USER"

  psql -U "$DB_USER" $db < /docker-entrypoint-initdb.d/settings-sql
done

echo
echo "Finished database setup."
echo
