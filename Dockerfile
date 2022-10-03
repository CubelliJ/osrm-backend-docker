FROM ubuntu:xenial

LABEL \
  maintainer="Peter Evans <mail@peterevans.dev>" \
  org.opencontainers.image.title="osrm-chile" \
  org.opencontainers.image.description="Docker image for the Open Source Routing Machine (OSRM) osrm-backend." \
  org.opencontainers.image.authors="Peter Evans <mail@peterevans.dev>" \
  org.opencontainers.image.url="https://github.com/peter-evans/osrm-backend-docker" \
  org.opencontainers.image.vendor="https://peterevans.dev" \
  org.opencontainers.image.licenses="MIT"

ENV OSRM_VERSION 5.22.0

# Let the container know that there is no TTY
ARG DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get -y update \
 && apt-get install -y -qq --no-install-recommends \
    build-essential \
    cmake \
    curl \
    ca-certificates \
    libbz2-dev \
    libstxxl-dev \
    libstxxl1v5 \
    libxml2-dev \
    libzip-dev \
    libboost-all-dev \
    lua5.2 \
    liblua5.2-dev \
    libtbb-dev \
    libluabind-dev \
    pkg-config \
    gcc \
    python-dev \
    python-setuptools

RUN apt-get clean 
RUN apt-get -y install python3-pip 
RUN pip3 install -U crcmod 
RUN rm -rf /var/lib/apt/lists/* 
RUN rm -rf /tmp/* /var/tmp/*

# Build osrm-backend
RUN mkdir /osrm-src \
 && cd /osrm-src \
 && curl --silent -L https://github.com/Project-OSRM/osrm-backend/archive/v$OSRM_VERSION.tar.gz -o v$OSRM_VERSION.tar.gz \
 && tar xzf v$OSRM_VERSION.tar.gz \
 && cd osrm-backend-$OSRM_VERSION \
 && mkdir build \
 && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=Release \
 && cmake --build . \
 && cmake --build . --target install \
 && mkdir /osrm-data \
 && mkdir /osrm-profiles \
 && cp -r /osrm-src/osrm-backend-$OSRM_VERSION/profiles/* /osrm-profiles \
 && rm -rf /osrm-src

# File download and configuration
RUN curl -L "http://download.geofabrik.de/south-america/chile-latest.osm.pbf" --create-dirs -o /osrm-data/data.osm.pbf
RUN osrm-extract /osrm-data/data.osm.pbf -p /osrm-profiles/car.lua
RUN osrm-contract /osrm-data/data.osm.pbf

# Set the entrypoint

ENV PORT=8080

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

# Defaults to 8080, I haven't been able to run it without defining it.
# https://cloud.google.com/run/docs/container-contract


#RUN osrm-routed /osrm-data/data.osrm --port ${PORT} --max-table-size 8000

#EXPOSE 5000


