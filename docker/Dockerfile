FROM ubuntu:24.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates make gcc-aarch64-linux-gnu g++-aarch64-linux-gnu dpkg-dev \
    git xz-utils && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN chmod +x scripts/build-deb.sh && scripts/build-deb.sh
