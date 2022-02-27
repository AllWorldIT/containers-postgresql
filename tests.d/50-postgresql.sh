#!/bin/sh

# Setup database credentials
cat <<EOF > /root/.pgpass
*:*:*:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_USER_PASSWORD
EOF
chmod 0600 /root/.pgpass


echo "CREATE TABLE testtable (id SERIAL PRIMARY KEY);" | psql -v ON_ERROR_STOP=ON -U "$POSTGRES_USER" "$POSTGRES_DATABASE"


