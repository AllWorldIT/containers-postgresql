#!/bin/sh


# Setup database credentials
cat <<EOF > /root/.pgpass
*:*:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_PASSWORD
EOF
chmod 0600 /root/.pgpass
# Test creating a table with the user which should own the database
echo "CREATE TABLE testtable (id SERIAL PRIMARY KEY, txt TEXT);" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="$POSTGRES_USER" "$POSTGRES_DATABASE"


# Setup database credentials
cat <<EOF > /root/.pgpass
*:*:$POSTGRES_DATABASE:postgres:$POSTGRES_ROOT_PASSWORD
EOF
# Test inserting data into the users database as the superuser
echo "INSERT INTO testtable (txt) VALUES ('test');" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="postgres" "$POSTGRES_DATABASE"
