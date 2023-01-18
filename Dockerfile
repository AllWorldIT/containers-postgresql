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


FROM registry.conarx.tech/containers/alpine/3.17


ENV POSTGRESQL_VERSION=15


ARG VERSION_INFO=
LABEL org.opencontainers.image.authors   = "Nigel Kukard <nkukard@conarx.tech>"
LABEL org.opencontainers.image.version   = "3.17"
LABEL org.opencontainers.image.base.name = "registry.conarx.tech/containers/alpine/3.17"


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
		icu-data-full \
		musl-locales \
		pwgen \
		sudo; \
	true "PostgreSQL"; \
	mkdir /var/lib/postgresql-initdb.d; \
	chmod 750 /var/lib/postgresql-initdb.d; \
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
	chown postgres:postgres /run/postgresql; \
	chmod 2777 /run/postgresql

RUN set -ex; \
	true "Cleaning up data directory"; \
	mkdir -p /var/lib/postgresql/data; \
	chown postgres:postgres \
		/var/lib/postgresql \
		/var/lib/postgresql/data; \
	chmod 750 \
		/var/lib/postgresql \
		/var/lib/postgresql/data

# PostgreSQL
COPY etc/supervisor/conf.d/postgresql.conf /etc/supervisor/conf.d/postgresql.conf
COPY usr/local/share/flexible-docker-containers/init.d/42-postgresql.sh /usr/local/share/flexible-docker-containers/init.d
COPY usr/local/share/flexible-docker-containers/pre-init-tests.d/42-postgresql.sh /usr/local/share/flexible-docker-containers/pre-init-tests.d
COPY usr/local/share/flexible-docker-containers/tests.d/42-postgresql.sh /usr/local/share/flexible-docker-containers/tests.d
COPY usr/local/share/flexible-docker-containers/healthcheck.d/42-postgresql.sh /usr/local/share/flexible-docker-containers/healthcheck.d
RUN set -ex; \
	true "Flexible Docker Containers"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	true "Permissions"; \
	fdc set-perms

# We set the default STOPSIGNAL to SIGINT, which corresponds to what PostgreSQL
# calls "Fast Shutdown mode" wherein new connections are disallowed and any
# in-progress transactions are aborted, allowing PostgreSQL to stop cleanly and
# flush tables to disk, which is the best compromise available to avoid data
# corruption.
# ref: https://github.com/docker-library/postgres/blob/master/Dockerfile-alpine.template
STOPSIGNAL SIGINT


VOLUME ["/var/lib/postgresql/data"]

EXPOSE 5432
