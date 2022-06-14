FROM phusion/baseimage:master-amd64
#########################
# see https://github.com/haiwen/seafile-docker/tree/master/image/seafile_8.0 for 
# official Dockerfile image (note it still contains nginx as of writing!);
# for additional clarity, also refer to the installation script @ https://github.com/haiwen/seafile-server-installer/blob/master/seafile-7.1_ubuntu
#########################

MAINTAINER    Laur

ENV DEBIAN_FRONTEND=noninteractive

## Give children processes x sec timeout on exit:
#ENV KILL_PROCESS_TIMEOUT=30
## Give all other processes (such as those which have been forked) x sec timeout on exit:
#ENV KILL_ALL_PROCESSES_TIMEOUT=30

# Seafile dependencies and system configuration
# - note ffmpeg, moviepy is for video thumbnails (https://github.com/haiwen/seafile-docs/blob/master/deploy/video_thumbnails.md)
# - note python-pil is instead of python-imaging
RUN apt-get -y update && \
    apt-get install --no-install-recommends -y \
        python3 \
        python3-pip \
        python3-setuptools \
        libmysqlclient-dev \
        wget \
        netcat \
        crudini \
        ffmpeg \
        vim \
        htop \
        unattended-upgrades && \

# deps for pylibmc:
    apt-get install --no-install-recommends -y \
        python3-dev \
        libmemcached-dev \
        zlib1g-dev \
        build-essential && \
# install pylibmc and friends..:
    pip3 install --timeout=3600 \
        click termcolor colorlog pymysql django==2.2.* \
        future mysqlclient Pillow pylibmc captcha jinja2 \
        sqlalchemy django-pylibmc django-simple-captcha pyjwt \
        moviepy lxml pycryptodome==3.12.0 cffi==1.14.0 && \
    ulimit -n 30000 && \
    update-locale LANG=C.UTF-8 && \
# prep dirs for seafile services' daemons:
    mkdir /etc/service/seafile /etc/service/seahub && \
# Clean up for smaller image:
    apt-get remove -y --purge --autoremove \
        python3-pip \
        python3-dev \
        build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*  /root/.cache/pip*

# note lxml is installed as otherwise seafile-installdir/logs/seafdav.log had this warning:
#          WARNING :  Could not import lxml: using xml instead (up to 10% slower). Consider `pip install lxml`(see https://pypi.python.org/pypi/lxml).


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
ADD common.sh /common.sh
ADD seafile.sh /etc/service/seafile/run
ADD seahub.sh /etc/service/seahub/run

ADD setup-seafile.sh /usr/local/sbin/setup-seafile
ADD download-seafile.sh /usr/local/sbin/download-seafile
ADD apt-auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades


EXPOSE 10001 12001 8000 8080 8082
VOLUME "/seafile"
WORKDIR "/seafile"
