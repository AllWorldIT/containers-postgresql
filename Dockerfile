FROM registry.gitlab.iitsp.com/allworldit/docker/alpine:latest

ENV POSTGRESQL_VERSION=15

ARG VERSION_INFO=
LABEL maintainer="Nigel Kukard <nkukard@lbsd.net>"

# 70 is the standard uid/gid for "postgres" in Alpine
# https://git.alpinelinux.org/aports/tree/main/postgresql/postgresql.pre-install?h=3.12-stable
RUN set -ex; \
	addgroup -g 70 -S postgres; \
	adduser -u 70 -S -D -G postgres -H -h /var/lib/postgresql -s /bin/sh postgres; \
	mkdir -p /var/lib/postgresql; \
	chown -R postgres:postgres /var/lib/postgresql

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
# alpine doesn't require explicit locale-file generation
ENV LANG en_US.utf8

RUN set -ex; \
	true "PostgreSQL"; \
	apk add --no-cache \
		postgresql$POSTGRESQL_VERSION \
		postgresql$POSTGRESQL_VERSION-client \
		postgresql$POSTGRESQL_VERSION-client \
		postgresql$POSTGRESQL_VERSION-jit \
		postgresql$POSTGRESQL_VERSION-contrib-jit \
		postgresql$POSTGRESQL_VERSION-plpython3 \
		postgresql$POSTGRESQL_VERSION-plpython3-contrib \
		musl-locales \
		pwgen \
		sudo; \
	true "PostgreSQL"; \
	mkdir /docker-entrypoint-initdb.d; \
	chmod 750 /docker-entrypoint-initdb.d; \
	true "Versioning"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	true "Cleanup"; \
	rm -f /var/cache/apk/*

# make the sample config easier to munge (and "correct by default")
RUN set -ex; \
	true "Cleaning up config file"; \
	cp -v /usr/share/postgresql/postgresql.conf.sample /usr/share/postgresql/postgresql.conf.sample.orig; \
	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
	grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

RUN set -ex; \
	true "Creating runtime directories"; \
	mkdir -p /run/postgresql; \
	chown -R postgres:postgres /run/postgresql; \
	chmod 2777 /run/postgresql

RUN set -ex; \
	true "Cleaning up data directory"; \
	mkdir -p "/var/lib/postgresql/data"; \
	chown -R postgres:postgres "/var/lib/postgresql/data"; \
	chmod 700 "/var/lib/postgresql/data"

# PostgreSQL
COPY etc/supervisor/conf.d/postgresql.conf /etc/supervisor/conf.d/postgresql.conf
COPY init.d/50-postgresql.sh /docker-entrypoint-init.d/50-postgresql.sh
COPY pre-init-tests.d/50-postgresql.sh /docker-entrypoint-pre-init-tests.d/50-postgresql.sh
COPY tests.d/50-postgresql.sh /docker-entrypoint-tests.d/50-postgresql.sh
RUN set -ex; \
		chown root:root \
			/etc/supervisor/conf.d/postgresql.conf \
			/docker-entrypoint-init.d/50-postgresql.sh \
			/docker-entrypoint-pre-init-tests.d/50-postgresql.sh \
			/docker-entrypoint-tests.d/50-postgresql.sh \
			; \
		chmod 0644 \
			/etc/supervisor/conf.d/postgresql.conf \
			; \
		chmod 0755 \
			/docker-entrypoint-init.d/50-postgresql.sh \
			/docker-entrypoint-pre-init-tests.d/50-postgresql.sh \
			/docker-entrypoint-tests.d/50-postgresql.sh

# We set the default STOPSIGNAL to SIGINT, which corresponds to what PostgreSQL
# calls "Fast Shutdown mode" wherein new connections are disallowed and any
# in-progress transactions are aborted, allowing PostgreSQL to stop cleanly and
# flush tables to disk, which is the best compromise available to avoid data
# corruption.
# ref: https://github.com/docker-library/postgres/blob/master/Dockerfile-alpine.template
STOPSIGNAL SIGINT


VOLUME ["/var/lib/postgresql/data"]

EXPOSE 5432

