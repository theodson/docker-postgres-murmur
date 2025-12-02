# Postgres with Murmur3 Hashlib extension `postgres-murmur`

- Based standard Postgres image

An image is available at [Docker Hub - theodson/postgres-murmur](https://hub.docker.com/repository/docker/theodson/postgres-murmur/tags)

## Build

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

# Build both architectures (pushes images tagged with :${TAG}-amd64 and :${TAG}-arm64)
./build.sh build
./build.sh push
./build.sh publish
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