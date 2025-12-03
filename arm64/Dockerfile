FROM postgres:9.5.14
# See https://github.com/docker-library/postgres/blob/d424c8f180ed614184059a953639d0a420477846/9.5/Dockerfile

ARG POSTGRES_VERSION=9.5

# Use murmur3 hashlib extension in postgresql 9.5
LABEL maintainer="Postgres ${POSTGRES_VERSION} with Murmur 3"

# debian stretch is archived as of 2025... change repositories to use archives
RUN rm /etc/apt/sources.list.d/pgdg.list \
    && echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list \
    && echo "deb-src [trusted=yes] http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list \
    && echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch-backports main" >> /etc/apt/sources.list \
    && echo "deb [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list \
    && echo "deb-src [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list

RUN apt update && apt install -y wget file

RUN wget -qO- https://github.com/bgdevlab/pghashlib/blob/bgdevlab/builds/builds/ubuntu/postgresql95-hashlib.aarch64-ubuntu_20.tar.gz?raw=true >/tmp/postgresql95-hashlib.arm64.tar.gz

# install pre-compiled hashlib postgresql extension.
RUN tar -xf /tmp/postgresql95-hashlib.arm64.tar.gz -C /tmp/ \
    && mv /tmp/pghashlib_9.5-ubuntu_20 /tmp/pghashlib_9.5-arm64 \
    && cd /tmp/pghashlib_9.5-arm64/ \
    && cp hashlib.so /usr/lib/postgresql/9.5/lib \
    && cp hashlib.control /usr/share/postgresql/9.5/extension/ \
    && cp sql/*.sql /usr/share/postgresql/9.5/extension/

RUN apt -y autoremove \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /docker-entrypoint-initdb.d
# See docker-compose
#COPY ./create-homestead-database.sql /docker-entrypoint-initdb.d/10-create-homestead-database.sql

RUN echo "Arch: $(uname -m), Date:$(date)" > /etc/BUILD_INFO
