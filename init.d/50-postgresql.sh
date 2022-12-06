#!/bin/sh


docker_temp_server_start() {
	TEMP_START_ARGS=( \
		"-c" "listen_addresses="
	)
	sudo -u postgres pg_ctl -D /var/lib/postgresql/data -o "$(printf '%q ' "${TEMP_START_ARGS[@]}")" -w start
}

docker_temp_server_stop() {
	sudo -u postgres pg_ctl -D /var/lib/postgresql/data -m fast -w stop
}


if [ -d "/run/postgresql" ]; then
	chown -R postgres:postgres /run/postgresql
else
	mkdir -p /run/postgresql
	chown -R postgres:postgres /run/postgresql
	chmod 2777 /run/postgresql
fi

if [ -f /var/lib/postgresql/data/PG_VERSION ]; then
	chown -R postgres:postgres /var/lib/postgresql/data
else
	echo "NOTICE: Initializing settings"

	# Check if we have stats enabled
	if [ -n "$POSTGRES_TRACK_STATS" ]; then
		sed -ri "s!^#?(track_counts)\s*=\s*\S+.*!\1 = 'on'!" /usr/share/postgresql/postgresql.conf.sample
		grep -F "track_counts = 'on'" /usr/share/postgresql/postgresql.conf.sample
		sed -ri "s!^#?(track_activities)\s*=\s*\S+.*!\1 = 'on'!" /usr/share/postgresql/postgresql.conf.sample
		grep -F "track_activities = 'on'" /usr/share/postgresql/postgresql.conf.sample
	fi

	echo "NOTICE: Data directory not found, initializing"

	chown -R postgres:postgres /var/lib/postgresql/data
	chmod 700 /var/lib/postgresql/data

	INITDB_ARGS=( \
		"--auth=scram-sha-256"
		"--auth-local=trust"
		"--encoding=UTF8"
		"--locale=en_US.UTF-8"
		"--lc-collate=und-x-icu"
		"--lc-ctype=und-x-icu"
		"--username=postgres"
	)

	if [ "$POSTGRES_PASSWORD" = "" ]; then
		POSTGRES_PASSWORD=`pwgen 16 1`
		echo "NOTICE: PostgreSQL password for 'postgres': $POSTGRES_PASSWORD"

		pwfile=`mktemp`
		if [ ! -f "$pwfile" ]; then
			return 1
		fi
		chown root:postgres "$pwfile"
		chmod 660 "$pwfile"
		echo -n "$POSTGRES_PASSWORD" > "$pwfile"

		INITDB_ARGS+=("--pwfile=$pwfile")
	fi

	echo "NOTICE: PostgreSQL initdb args: ${INITDB_ARGS[@]}"
	sudo -u postgres initdb ${INITDB_ARGS[@]} /var/lib/postgresql/data


	POSTGRES_DATABASE=${POSTGRES_DATABASE:-""}
	POSTGRES_USER=${POSTGRES_USER:-""}
	POSTGRES_USER_PASSWORD=${POSTGRES_USER_PASSWORD:-""}

	# Start server temporarily
	docker_temp_server_start


	tfile=`mktemp`
	if [ ! -f "$tfile" ]; then
		return 1
	fi


	if [ -n "$POSTGRES_USER" ]; then
		echo "NOTICE: Creating user [$POSTGRES_USER] with password [$POSTGRES_USER_PASSWORD]"
		cat << EOF > "$tfile"
CREATE USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '${POSTGRES_USER_PASSWORD}';
EOF
	fi

	if [ -n "$POSTGRES_DATABASE" ]; then
		DATABASE_OPTIONS=()
		echo "NOTICE: Creating database [$POSTGRES_DATABASE]"

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
			echo "INFO: Database ENCODING [$POSTGRES_ENCODING], LC_COLLATE [$POSTGRES_LC_COLLATE], LC_CTYPE [$POSTGRES_LC_CTYPE]"
			echo "CREATE DATABASE $POSTGRES_DATABASE ${DATABASE_OPTIONS[@]};" >> "$tfile"
		else
			echo "INFO: Database with default encoding and collation"
			echo "CREATE DATABASE $POSTGRES_DATABASE;" >> "$tfile"
		fi

		if [ -n "$POSTGRES_USER" ]; then
			echo "NOTICE: Granting user [$POSTGRES_USER] access to database [$POSTGRES_DATABASE]"
			echo "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DATABASE TO $POSTGRES_USER;" >> "$tfile"
			echo "\\c $POSTGRES_DATABASE postgres" >> "$tfile"
			echo "GRANT ALL ON SCHEMA public TO $POSTGRES_USER;" >> "$tfile"
		fi
	fi

	# Create database and user
	sudo -u postgres psql -v ON_ERROR_STOP=ON < "$tfile"
	rm -f $tfile


	# Load data
	find /docker-entrypoint-initdb.d -type f | sort | while read f
	do
		case "$f" in
			*.sql)    echo "NOTICE: initdb.d - Loading [$f]"; sudo -u postgres psql < "$f"; echo ;;
			*.sql.gz) echo "NOTICE: initdb.d - Loading [$f]"; gunzip -c "$f" | sudo -u postgres psql; echo ;;
			*.sql.xz) echo "NOTICE: initdb.d - Loading [$f]"; unxz -c "$f" | sudo -u postgres psql; echo ;;
			*.sql.zst) echo "NOTICE: initdb.d - Loading [$f]"; unzstd -c "$f" | sudo -u postgres psql; echo ;;
			*)        echo "WARNING: Ignoring initdb entry [$f]" ;;
		esac
	done

	# All remote host connections
	echo "host all all all scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf

	docker_temp_server_stop
fi


