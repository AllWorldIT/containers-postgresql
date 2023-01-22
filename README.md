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



# Conarx Containers

All our Docker images are part of our Conarx Containers product line. Images are generally based on Alpine Linux and track the
Alpine Linux major and minor version in the format of `vXX.YY`.

Images built from source track both the Alpine Linux major and minor versions in addition to the main software component being
built in the format of `vXX.YY-AA.BB`, where `AA.BB` is the main software component version.

Our images are built using our Flexible Docker Containers framework which includes the below features...

- Flexible container initialization and startup
- Integrated unit testing
- Advanced multi-service health checks
- Native IPv6 support for all containers
- Debugging options



# Community Support

Please use the project [Issue Tracker](https://gitlab.conarx.tech/containers/postgresql/-/issues).



# Commercial Support

Commercial support for all our Docker images is available from [Conarx](https://conarx.tech).

We also provide consulting services to create and maintain Docker images to meet your exact needs.



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


## /var/lib/postgresql/data

PostgreSQL data directory.



# Preloading SQL on Database Creation

## Directory: /var/lib/postgresql-initdb.d

Any file in this directory with a .sql, .sql.gz, .sql.xz or .sql.zst extension will be loaded into the database apon initialization.



# Exposed Ports

PostgreSQL port 5432 is exposed.
