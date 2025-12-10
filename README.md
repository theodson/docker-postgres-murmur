# Postgres with Murmur3 Hashlib extension `postgres-murmur`

- Based on the standard Postgres image

An image is available at [Docker Hub - theodson/postgres-murmur](https://hub.docker.com/repository/docker/theodson/postgres-murmur/tags)

## Build

**Prerequisites**

- Docker 24+ with Buildx
- logged in to Docker Hub if pushing.

**Build locally** (when archives are reachable)

Build both architectures, create a manifest and publish to Docker Hub with `build.sh`:

>  Note: building for a different architecture is supported regardless of the host/build machines architevture/platform.

```bash
# Optional: override defaults
export DOCKERID="theodson/" # your Docker Hub namespace

# Authenticate for your Docker Hub account
docker login

# What version of Postgres to build (TAG is based on POSTGRES_VERSION)
export POSTGRES_VERSION=15

# Build both architectures (pushes images tagged with :${TAG}-amd64 and :${TAG}-arm64)
./build.sh build
./build.sh push
./build.sh publish
```

or target a single architecture:
```bash
# Build a single architecture tagged with :${VERSION}-arm64 (15-arm64)
DOCKERID=theodson POSTGRES_VERSION=15 ./build.sh build_arm64

# Build and push a single architecture tagged with :${VERSION}-arm64 (18-arm64)
DOCKERID=theodson POSTGRES_VERSION=18 ./build.sh push_arm64
```

## Publish

This was published using the following commands
```bash
# Authenticate for your DockerHub account
docker login

# Assuming images are built and pushed (see previous examples)
./build.sh publish
```

## Docker Compose 

An example of use with Docker compose

```yaml
name: postgres-murmur3
services:
    pgsql:
#        build:
#            context: './docker/pgsql'
#            dockerfile: Dockerfile
        image: 'postgres-murmur:9.5'
        ports:
            - '${FORWARD_DB_PORT:-5439}:5432'
        environment:
            PGPASSWORD: '${DB_PASSWORD:-secret}'
            POSTGRES_DB: '${DB_DATABASE}'
            POSTGRES_USER: '${DB_USERNAME}'
            POSTGRES_PASSWORD: '${DB_PASSWORD:-secret}'
        volumes:
            - 'sail-pgsql:/var/lib/postgresql/data'
            - './docker/pgsql/create-homestead-database.sql:/docker-entrypoint-initdb.d/10-create-homestead-databases.sql'
        networks:
            - sail
        healthcheck:
            test:
                - CMD
                - pg_isready
                - '-q'
                - '-d'
                - '${DB_DATABASE}'
                - '-U'
                - '${DB_USERNAME}'
            retries: 3
            timeout: 5s
```

Check 
```bash

# check hashlib is installed using commands
psql -U postgres -c 'CREATE EXTENSION hashlib;'
psql -U postgres -t -c "select encode(hash128_string('abcdefg', 'murmur3'), 'hex');" | xargs | grep '069b3c88000000000000000000000000'
```