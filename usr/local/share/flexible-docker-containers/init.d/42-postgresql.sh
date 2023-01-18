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


docker_temp_server_start() {
	TEMP_START_ARGS=( \
		"-c" "listen_addresses="
	)
	sudo -u postgres pg_ctl -D /var/lib/postgresql/data -o "$(printf '%q ' "${TEMP_START_ARGS[@]}")" -w start
}

docker_temp_server_stop() {
	sudo -u postgres pg_ctl -D /var/lib/postgresql/data -m fast -w stop
}



echo "NOTICE: Setting PostgreSQL permissions"
chown postgres:postgres /var/lib/postgresql
chmod 750 /var/lib/postgresql
if [ -d /var/lib/postgresql/data ]; then
	chown postgres:postgres /var/lib/postgresql/data
	chown 750 /var/lib/postgresql/data
fi

if [ ! -f /var/lib/postgresql/data/PG_VERSION ]; then
	echo "NOTICE: Initializing PostgreSQL settings"

	# Check if we have stats enabled
	if [ -n "$POSTGRES_TRACK_STATS" ]; then
		sed -ri "s!^#?(track_counts)\s*=\s*\S+.*!\1 = 'on'!" /usr/share/postgresql/postgresql.conf.sample
		grep -F "track_counts = 'on'" /usr/share/postgresql/postgresql.conf.sample
		sed -ri "s!^#?(track_activities)\s*=\s*\S+.*!\1 = 'on'!" /usr/share/postgresql/postgresql.conf.sample
		grep -F "track_activities = 'on'" /usr/share/postgresql/postgresql.conf.sample
	fi

	echo "NOTICE: PostgreSQL data directory not found, initializing"

	INITDB_ARGS=( \
		"--auth=scram-sha-256"
		"--auth-local=trust"
		"--encoding=UTF8"
		"--locale=en_US.UTF-8"
		"--lc-collate=und-x-icu"
		"--lc-ctype=und-x-icu"
		"--username=postgres"
	)


	# Setup database superuser password
	if [ -z "$POSTGRES_ROOT_PASSWORD" ]; then
		POSTGRES_ROOT_PASSWORD=`pwgen 16 1`
		echo "NOTICE: PostgreSQL password for 'postgres': $POSTGRES_ROOT_PASSWORD"
	fi
	pwfile=`mktemp`
	if [ ! -f "$pwfile" ]; then
		return 1
	fi
	chown root:postgres "$pwfile"
	chmod 660 "$pwfile"

	echo -n "$POSTGRES_ROOT_PASSWORD" > "$pwfile"
	INITDB_ARGS+=("--pwfile=$pwfile")

	# Run database initialization
	echo "NOTICE: PostgreSQL initdb args: ${INITDB_ARGS[@]}"
	sudo -u postgres initdb ${INITDB_ARGS[@]} /var/lib/postgresql/data


	POSTGRES_DATABASE=${POSTGRES_DATABASE:-""}
	POSTGRES_USER=${POSTGRES_USER:-""}
	POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-""}

	# Start server temporarily
	docker_temp_server_start

	tfile=`mktemp`
	if [ ! -f "$tfile" ]; then
		return 1
	fi

	if [ -n "$POSTGRES_USER" ]; then
		echo "NOTICE: Creating user [$POSTGRES_USER] with password [$POSTGRES_PASSWORD]"
		cat << EOF > "$tfile"
CREATE USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '${POSTGRES_PASSWORD}';
EOF
	fi

	if [ -n "$POSTGRES_DATABASE" ]; then
		DATABASE_OPTIONS=()
		echo "NOTICE: Creating PostgreSQL database [$POSTGRES_DATABASE]"

		if [ -n "$POSTGRES_ENCODING" ]; then
			DATABASE_OPTIONS+=("ENCODING = '$POSTGRES_ENCODING'")
		fi

		if [ -n "$POSTGRES_LC_COLLATE" ]; then
			DATABASE_OPTIONS+=("LC_COLLATE = '$POSTGRES_LC_COLLATE'")
		fi

		if [ -n "$POSTGRES_LC_CTYPE" ]; then
			DATABASE_OPTIONS+=("LC_CTYPE = '$POSTGRES_LC_CTYPE'")
		fi

		if [ "${#DATABASE_OPTIONS[@]}" -gt 0 ]; then
			echo "INFO: PostgreSQL database ENCODING [$POSTGRES_ENCODING], LC_COLLATE [$POSTGRES_LC_COLLATE], LC_CTYPE [$POSTGRES_LC_CTYPE]"
			echo "CREATE DATABASE $POSTGRES_DATABASE ${DATABASE_OPTIONS[@]};" >> "$tfile"
		else
			echo "INFO: PostgreSQL database with default encoding and collation"
			echo "CREATE DATABASE $POSTGRES_DATABASE;" >> "$tfile"
		fi

		if [ -n "$POSTGRES_USER" ]; then
			echo "NOTICE: Granting PostgreSQL user [$POSTGRES_USER] access to database [$POSTGRES_DATABASE]"
			echo "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DATABASE TO $POSTGRES_USER;" >> "$tfile"
			echo "\\c $POSTGRES_DATABASE postgres" >> "$tfile"
			echo "GRANT ALL ON SCHEMA public TO $POSTGRES_USER;" >> "$tfile"
		fi
	fi

	# Create database and user
	sudo -u postgres psql -v ON_ERROR_STOP=ON < "$tfile"
	rm -f "$tfile"

	# Load data
	find /var/lib/mysql-initdb.d -type f | sort -n | while read f
	do
		case "$f" in
			*.sql)
				echo "NOTICE: postgresql-initdb.d - Loading [$f]"
				sudo -u postgres psql < "$f"
				echo
				;;
			*.sql.gz)
				echo "NOTICE: postgresql-initdb.d - Loading [$f]"
				gunzip -c "$f" | sudo -u postgres psql
				echo
				;;
			*.sql.xz)
				echo "NOTICE: postgresql-initdb.d - Loading [$f]"
				unxz -c "$f" | sudo -u postgres psql
				echo
				;;
			*.sql.zst)
				echo "NOTICE: postgresql-initdb.d - Loading [$f]"
				unzstd -c "$f" | sudo -u postgres psql
				echo
				;;
			*)
				echo "WARNING: Ignoring postgresql-initdb.d entry [$f]"
				;;
		esac
	done

	# All remote host connections
	echo "host all all all scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf

	docker_temp_server_stop
fi

echo "NOTICE: Setting PostgreSQL data directory permissions"
chown postgres:postgres /var/lib/postgresql/data
chmod 750 /var/lib/postgresql/data
