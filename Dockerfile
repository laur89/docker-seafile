FROM phusion/baseimage:0.11
#########################
# see https://github.com/haiwen/seafile-docker/tree/master/image/seafile_7.1 for 
# official image (note it still contains nginx as of writing!)
#########################

MAINTAINER    Laur

ENV DEBIAN_FRONTEND=noninteractive

## Give children processes x sec timeout on exit:
#ENV KILL_PROCESS_TIMEOUT=30
## Give all other processes (such as those which have been forked) x sec timeout on exit:
#ENV KILL_ALL_PROCESSES_TIMEOUT=30

# Seafile dependencies and system configuration
# - note ffmpeg, pillow, moviepy is for video thumbnails (https://github.com/haiwen/seafile-docs/blob/master/deploy/video_thumbnails.md)
# - note python-pil is instead of python-imaging
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        python2.7 \
        libpython2.7 \
        python-setuptools \
        python-pil \
        python-mysqldb \
        python-urllib3 \
        python-memcache \
        wget \
        netcat \
        crudini \
        ffmpeg \
        unattended-upgrades && \
    update-locale LANG=C.UTF-8

# deps for pylibmc:
RUN apt-get install --no-install-recommends -y \
        python-pip \
        libmemcached-dev \
        zlib1g-dev \
        python-dev \
        build-essential && \
    pip install pylibmc django-pylibmc pillow moviepy && \
    ulimit -n 30000


EXPOSE 10001 12001 8000 8080 8082

# TODO: do we want to download in dockerfile, and house the binary within container (by foxel)?:
#ENV SEAFILE_VERSION 7.0.5
#ENV SEAFILE_PATH "/opt/seafile/seafile-server-$SEAFILE_VERSION"
#
#RUN \
#    mkdir -p /seafile "${SEAFILE_PATH}" && \
#    wget --progress=dot:mega --no-check-certificate -O /tmp/seafile-server.tar.gz \
#        "https://download.seadrive.org/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz" && \
#    tar -xzf /tmp/seafile-server.tar.gz --strip-components=1 -C "${SEAFILE_PATH}" && \
#    sed -ie '/^daemon/d' "${SEAFILE_PATH}/runtime/seahub.conf" && \
#    rm /tmp/seafile-server.tar.gz \ &&
#    useradd -r -s /bin/false seafile && \
#    chown seafile:seafile /seafile "$SEAFILE_PATH"


# Baseimage init process
ENTRYPOINT ["/sbin/my_init"]

# Seafile daemons
RUN mkdir /etc/service/seafile /etc/service/seahub
ADD common.sh /common.sh
ADD seafile.sh /etc/service/seafile/run
ADD seahub.sh /etc/service/seahub/run

ADD setup-seafile.sh /usr/local/sbin/setup-seafile
ADD download-seafile.sh /usr/local/sbin/download-seafile
ADD apt-auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

# Clean up for smaller image
RUN apt-get purge -y \
        python-pip \
        zlib1g-dev \
        python-dev \
        build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME "/seafile"
WORKDIR "/seafile"
