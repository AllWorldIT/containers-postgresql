[![pipeline status](https://gitlab.conarx.tech/containers/postgresql/badges/main/pipeline.svg)](https://gitlab.conarx.tech/containers/postgresql/-/commits/main)

# Container Information

[Container Source](https://gitlab.conarx.tech/containers/postgresql) - [GitHub Mirror](https://github.com/AllWorldIT/containers-postgresql)

This is the Conarx Containers PostgreSQL image, it provides the PostgreSQL database server.

Additional features:
* PostgreSQL JIT
* Preloading of SQL into a new database apon creation



# Mirrors

|  Provider  |  Repository                                |
|------------|--------------------------------------------|
| DockerHub  | allworldit/postgresql                      |
| Conarx     | registry.conarx.tech/containers/postgresql |



# Commercial Support

Commercial support is available from [Conarx](https://conarx.tech).



# Environment Variables

Additional environment variables are available from...
* [Conarx Containers Alpine image](https://gitlab.conarx.tech/containers/alpine).


## POSTGRES_ROOT_PASSWORD

Optional password for the `postgres` user, set when the database its created. If not assigned, it will be automatically generated and output in the logs.


## POSTGRES_DATABASE

Optional name database to create.


## POSTGRES_USER

Optional user to create for the database. It will be granted access to the `POSTGRES_DATABASE` database.


## POSTGRES_PASSWORD

Optional password to set for `POSTGRES_PASSWORD`.


## POSTGRES_ENCODING

Optional encoding set for the database. Deafults to `UTF8`.


## POSTGRES_LOCALE

Optional locale for the database. Deafults to `en_US.UTF-8`.


## POSTGRES_COLLATE

Optional collation for the database. Deafults to `und-x-icu`.


## POSTGRES_CTYPE

Optional CTYPE for the database. Deafults to `und-x-icu`.


## POSTGRES_TRACK_STATS

Track PostgreSQL statistics by enabling `track_activities` and `track_counts`.



# Volumes


## /var/lib/postgresql

PostgreSQL data directory.



# Preloading SQL on Database Creation

## Directory: /var/lib/postgresql-initdb.d

Any file in this directory with a .sql, .sql.gz, .sql.xz or .sql.zst extension will be loaded into the database apon initialization.



# Exposed Ports

PostgreSQL port 5432 is exposed.
