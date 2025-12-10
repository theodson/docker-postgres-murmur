FROM postgres:12

ARG POSTGRES_VERSION=12

# Use murmur3 hashlib extension in postgresql 12
LABEL maintainer="Postgres ${POSTGRES_VERSION} with Murmur 3"

RUN apt update && apt install -y wget file

RUN wget -qO- https://github.com/bgdevlab/pghashlib/blob/bgdevlab/builds/builds/ubuntu/postgresql12-hashlib.x86_64.tar.gz?raw=true >/tmp/postgresql12-hashlib.x86_64.tar.gz

# install pre-compiled hashlib postgresql extension.
RUN tar -xf /tmp/postgresql12-hashlib.x86_64.tar.gz -C /tmp/ \
    && mv /tmp/pghashlib_12 /tmp/pghashlib_12-x86_64 \
    && cd /tmp/pghashlib_12-x86_64/ \
    && cp hashlib.so /usr/lib/postgresql/12/lib \
    && cp hashlib.control /usr/share/postgresql/12/extension/ \
    && cp sql/*.sql /usr/share/postgresql/12/extension/

RUN apt -y autoremove \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /docker-entrypoint-initdb.d
# See docker-compose
#COPY ./create-homestead-database.sql /docker-entrypoint-initdb.d/10-create-homestead-database.sql

RUN echo "Arch: $(uname -m), Date:$(date)" > /etc/BUILD_INFO
