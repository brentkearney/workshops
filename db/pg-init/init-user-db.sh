#!/bin/bash
set -e

echo
echo "Setting up $DB_USER and Workshops databases..."
echo
psql -U "$POSTGRES_USER" -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
echo

for db in workshops_test workshops_development workshops_production
do
  echo
  echo "Setting up $db database..."
  psql -U "$POSTGRES_USER" -c "CREATE DATABASE $db OWNER=$DB_USER
    ENCODING 'UTF8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8'"

  psql -U "$POSTGRES_USER" -c "GRANT ALL PRIVILEGES ON DATABASE $db to $DB_USER"

  echo
  echo "Loading default data into $db..."
  cd /docker-entrypoint-initdb.d/; psql -U "$DB_USER" $db < settings-sql
done

echo
echo "Finished database setup."
echo
