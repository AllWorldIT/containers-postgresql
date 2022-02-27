# Introduction

This is a Postgresql container.

See the [Alpine Base Image](https://gitlab.iitsp.com/allworldit/docker/alpine) project for additional configuration.

# PostgreSQL

The following directories can be mapped in:

## Directory: /docker-entrypoint-initdb.d

Any file in this directory with a .sql, .sql.gz, .sql.xz or .sql.zst extension will be loaded into the database apon initialization.

## Volume: /var/lib/postgresql/data

Data directory.

## POSTGRES_PASSWORD

Optional `postgres` password for the database when its created. If not assigned, it will be automatically generated and output in the logs.

## POSTGRES_DATABASE

Optional database to create.

## POSTGRES_USER

Optional user to create for the database. It will be granted access to the `POSTGRES_DATABASE` database.

## POSTGRES_USER_PASSWORD

Optional password to set for `POSTGRES_USER_PASSWORD`.


## POSTGRES_ENCODING

Optional encoding set for the database. Deafults to `UTF8`.


## POSTGRES_LOCALE

Optional locale for the database. Deafults to `en_US.UTF-8`.


## POSTGRES_COLLATE

Optional collation for the database. Deafults to `und-x-icu`.


## POSTGRES_CTYPE

Optional CTYPE for the database. Deafults to `und-x-icu`.


