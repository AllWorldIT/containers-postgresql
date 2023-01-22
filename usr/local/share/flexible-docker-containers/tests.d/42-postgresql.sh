#!/bin/bash
# Copyright (c) 2022-2023, AllWorldIT.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.


# Setup database credentials
cat <<EOF > /root/.pgpass
*:*:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_PASSWORD
EOF
chmod 0600 /root/.pgpass

fdc_test_start postgresql "Test create table..."
# Test creating a table with the user which should own the database
echo "CREATE TABLE testtable (id SERIAL PRIMARY KEY, txt TEXT);" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="$POSTGRES_USER" "$POSTGRES_DATABASE"
fdc_test_pass postgresql "Test table created"

# Setup database credentials
cat <<EOF > /root/.pgpass
*:*:$POSTGRES_DATABASE:postgres:$POSTGRES_ROOT_PASSWORD
EOF

fdc_test_start postgresql "Test insert data in table..."
# Test inserting data into the users database as the superuser
echo "INSERT INTO testtable (txt) VALUES ('test');" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="postgres" "$POSTGRES_DATABASE"
fdc_test_pass postgresql "Test data inserted into table"
