#!/bin/sh

# Setup database credentials
cat <<EOF > /root/.pgpass
*:*:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_USER_PASSWORD
EOF
chmod 0600 /root/.pgpass


echo "CREATE TABLE testtable (id SERIAL PRIMARY KEY);" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="$POSTGRES_USER" "$POSTGRES_DATABASE"


