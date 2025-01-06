#!/bin/bash
# Copyright (c) 2022-2025, AllWorldIT.
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


# Test creating a table
fdc_test_start postgresql "Test create table..."
if ! echo "CREATE TABLE testtable (id SERIAL PRIMARY KEY, txt TEXT);" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="$POSTGRES_USER" "$POSTGRES_DATABASE"; then
    fdc_test_fail postgresql "Failed to create table 'testtable'"
    false
fi
fdc_test_pass postgresql "Test table created"


# Test inserting data
fdc_test_start postgresql "Test insert data in table..."
if ! echo "INSERT INTO testtable (txt) VALUES ('test');" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="$POSTGRES_USER" "$POSTGRES_DATABASE"; then
    fdc_test_fail postgresql "Failed to insert data into test table 'testtable'"
    false
fi
fdc_test_pass postgresql "Test data inserted into table"


# Test selecting data
fdc_test_start postgresql "Test SELECT on inserted data..."
if ! echo "SELECT * FROM testtable;" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="$POSTGRES_USER" "$POSTGRES_DATABASE"; then
    fdc_test_fail postgresql "Failed to SELECT data"
    false
fi
fdc_test_pass postgresql "Test SELECT on inserted data worked"


# Test extension
fdc_test_start postgresql "Test an extension works..."
if ! echo "SELECT difference('hello', 'world');" | psql --set=ON_ERROR_STOP=ON --host=127.0.0.1 --user="$POSTGRES_USER" "$POSTGRES_DATABASE"; then
    fdc_test_fail postgresql "Failed to make use of extension"
    false
fi
fdc_test_pass postgresql "Test of extension worked"
