# Postgres with Murmur3 Hashlib extension `postgres-murmur`

- Based standard Postgres image

An image is available at [Docker Hub - theodson/postgres-murmur](https://hub.docker.com/repository/docker/theodson/postgres-murmur/tags)


## Publish

This was published using the following commands
```bash
# Authenticate for your DockerHub account
docker login

# Prepare and Tag local image for the DockerHub repository.
docker tag postgres-murmur theodson/postgres-murmur:9.5.14

# Push to Docker Hub

docker push theodson/postgres-murmur:9.5.14
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
        image: 'postgres-murmur:9.5.14'
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