# 1: Use ruby 2.4.1 alpine as base:
FROM ruby:2.4.1-alpine

# 2: Set the application path as the working directory
WORKDIR /usr/src/app

# 3: We'll set the working dir as HOME and add the app's binaries path to $PATH:
# NOTE: The PAGER variable allows Pry to work on alpine linux.
# See https://github.com/pry/pry/issues/1494
ENV HOME=/usr/src/app PATH=/usr/src/app/bin:$PATH PAGER='busybox less' TERM='xterm-256color'

# ==================================================================================================
# 4:  Install development and runtime dependencies:

# 4.1: Install the development & runtime packages:
RUN set -ex && apk add --no-cache build-base bash ca-certificates openssl tzdata su-exec

# 4.2: Install Git version > 2.5 (a fuss in alpine!)
# NOTE: git@edge can't fetch from HTTPS without libcurl@edge (it segfaults with normal libcurl)
# Hence we'll install libcurl + curl alongside git:
RUN set -ex && \
    cat /etc/apk/repositories > /tmp/repo-backup && \
    echo 'http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories && \
    apk add --no-cache --force git@edge libcurl@edge curl@edge && \
    mv -f /tmp/repo-backup /etc/apk/repositories

# 4.3: Install the Docker client, which we need to test the go-fetch gem launching & operation
# of the Go Fetch! container:
# Install commands based on https://hub.docker.com/_/docker Dockerfiles:
RUN set -ex && \
    export DOCKER_BUCKET=get.docker.com && \
    export DOCKER_VERSION=17.03.1-ce && \
    export DOCKER_SHA256=820d13b5699b5df63f7032c8517a5f118a44e2be548dd03271a86656a544af55 && \
    curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz && \
    echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - && \
    tar -xzvf docker.tgz && \
    mv docker/* /usr/local/bin/ && \
    rmdir docker && \
    rm docker.tgz

# 4.4: Copy just the Gemfile & Gemfile.lock, to avoid the build cache failing whenever any other
# file changed and installing dependencies all over again - a must if your'e developing this
# Dockerfile...
ADD ./Gemfile* /usr/src/app/

# 4.5: Install the app gems:
RUN set -ex && bundle install --jobs 4 --retry 3

# 5: Set the default command:
CMD [ "bundle", "console" ]
