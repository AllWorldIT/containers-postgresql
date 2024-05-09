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


FROM registry.conarx.tech/containers/alpine/edge as builder

ENV POSTGRESQL_VER=16.3
# This must ALSO be set below in the actual image build
ENV LLVM_VER=15


# Copy build patches
COPY patches build/patches


RUN set -eux; \
	true "Installing build dependencies"; \
# from https://git.alpinelinux.org/aports/tree/main/postgresql15/APKBUILD
	apk add --no-cache \
		build-base \
		patch \
		sudo \
		\
		clang$LLVM_VER \
		icu-dev \
		llvm$LLVM_VER \
		lz4-dev \
		openssl-dev \
		zstd-dev \
		\
		bison \
		flex \
		libxml2-dev \
		linux-headers \
		llvm$LLVM_VER-dev \
		openldap-dev \
		perl-dev \
		python3-dev \
		readline-dev \
		tcl-dev \
		util-linux-dev \
		zlib-dev \
		\
		diffutils \
		icu-data-full \
		perl-ipc-run \
		; \
	true "Cleanup"; \
	rm -f /var/cache/apk/*

# Download tarballs
RUN set -eux; \
	mkdir -p build; \
	cd build; \
	# PostgreSQL
	wget "https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VER/postgresql-$POSTGRESQL_VER.tar.bz2"; \
	tar -jxf "postgresql-$POSTGRESQL_VER.tar.bz2"

# Build
RUN set -eux; \
	cd build; \
	cd "postgresql-$POSTGRESQL_VER"; \
# Patching
	patch -p1 < ../patches/disable-html-docs.patch; \
	patch -p1 < ../patches/dont-use-locale-a-on-musl.patch; \
	patch -p1 < ../patches/initdb.patch; \
	patch -p1 < ../patches/libpgport-pkglibdir.patch.txt; \
	patch -p1 < ../patches/perl-rpath.patch; \
	patch -p1 < ../patches/remove-libecpg_compat.patch; \
	patch -p1 < ../patches/unix_socket_directories.patch; \
	patch -p1 < ../patches/icu-collations-hack.patch; \
	\
	export LLVM_CONFIG=/usr/lib/llvm$LLVM_VER/bin/llvm-config; \
	# older clang versions don't have a 'clang' anymore.
	export CLANG=clang-$LLVM_VER; \
	\
	pkgname=postgresql; \
	_bindir=usr/bin; \
	_datadir=usr/share/$pkgname; \
	_docdir=usr/share/doc/$pkgname; \
	_mandir=$_datadir/man; \
	_includedir=usr/include/postgresql; \
	# Directory for server-related libraries. This is hard-coded in
	# per-version-dirs.patch.
	_srvlibdir=usr/lib/$pkgname; \
	\
	./configure \
		--prefix=/usr \
		--bindir=/$_bindir \
		--datarootdir=/usr/share \
		--datadir=/$_datadir \
		--docdir=/$_docdir \
		--includedir=/$_includedir \
		--libdir=/usr/lib \
		--mandir=/$_mandir \
		--sysconfdir=/etc/postgresql \
		--disable-rpath \
		--disable-static \
		--with-system-tzdata=/usr/share/zoneinfo \
		--with-libxml \
		--with-openssl \
		--with-uuid=e2fs \
		--with-llvm \
		--with-icu \
		--with-perl \
		--with-python \
		--with-tcl \
		--with-lz4 \
		--with-zstd \
		--with-ldap \
		--enable-tap-tests \
		; \
	\
# Build
	make VERBOSE=1 -j$(nproc) -l 8 world

# Install
RUN set -eux; \
	cd build; \
	cd "postgresql-$POSTGRESQL_VER"; \
	make DESTDIR="/build/postgresql-root" install; \
	make DESTDIR="/build/postgresql-root" -C contrib install; \
	find /build/postgresql-root -name "*.a" -print0 | xargs -0 rm -fv; \
	echo "Size before stripping..."; \
	du -hs /build/postgresql-root

# Strip binaries
RUN set -eux; \
	cd build/postgresql-root; \
	scanelf --recursive --nobanner --osabi --etype "ET_DYN,ET_EXEC" .  | awk '{print $3}' | xargs \
		strip \
			--remove-section=.comment \
			--remove-section=.note \
			-R .gnu.lto_* -R .gnu.debuglto_* \
			-N __gnu_lto_slim -N __gnu_lto_v1 \
			--strip-unneeded; \
	echo "Size after stripping..."; \
	du -hs /build/postgresql-root

# Testing
# NK: We run this after the installation so we have access to libpq.so
RUN set -eux; \
	# Install Postgresql so we can run the installcheck tests below
	tar -c -C /build/postgresql-root . | tar -x -C /; \
	# For testing we need to run the tests as a non-priv user
	cd build; \
	adduser -D pgsqltest; \
	chown -R pgsqltest:pgsqltest "postgresql-$POSTGRESQL_VER"; \
	cd "postgresql-$POSTGRESQL_VER"; \
	# Test
	sudo -u pgsqltest make VERBOSE=1 -j$(nproc) -l8 check MAX_CONNECTIONS=$(nproc)



FROM registry.conarx.tech/containers/alpine/edge


ENV LLVM_VER=15


COPY --from=builder /build/postgresql-root /


ARG VERSION_INFO=
LABEL org.opencontainers.image.authors   "Nigel Kukard <nkukard@conarx.tech>"
LABEL org.opencontainers.image.version   "edge"
LABEL org.opencontainers.image.base.name "registry.conarx.tech/containers/alpine/edge"


# 70 is the standard uid/gid for "postgres" in Alpine
# https://git.alpinelinux.org/aports/tree/main/postgresql/postgresql.pre-install?h=3.12-stable
RUN set -eux; \
	addgroup -g 70 -S postgres; \
	adduser -u 70 -S -D -G postgres -H -h /var/lib/postgresql -s /bin/sh postgres; \
	mkdir -p /var/lib/postgresql; \
	chown -R postgres:postgres /var/lib/postgresql

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
# alpine doesn't require explicit locale-file generation
ENV LANG en_US.utf8

RUN set -eux; \
	true "PostgreSQL"; \
	apk add --no-cache \
		icu-libs \
		libldap \
		libxml2 \
		llvm$LLVM_VER-libs \
		lz4-libs \
		zstd-libs \
		icu-data-full \
		musl-locales \
		pwgen \
		tzdata \
		sudo; \
	true "PostgreSQL"; \
	mkdir /var/lib/postgresql-initdb.d; \
	chmod 750 /var/lib/postgresql-initdb.d; \
	true "Cleanup"; \
	rm -f /var/cache/apk/*

# make the sample config easier to munge (and "correct by default")
RUN set -eux; \
	true "Cleaning up config file"; \
	cp -v /usr/share/postgresql/postgresql.conf.sample /usr/share/postgresql/postgresql.conf.sample.orig; \
	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
	grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

RUN set -eux; \
	true "Creating runtime directories"; \
	mkdir -p /run/postgresql; \
	chown postgres:postgres /run/postgresql; \
	chmod 2777 /run/postgresql

RUN set -eux; \
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
RUN set -eux; \
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
