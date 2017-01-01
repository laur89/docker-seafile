# Seafile for Docker

[Seafile](http://www.seafile.com/) is a "next-generation open source cloud storage
with advanced features on file syncing, privacy protection and teamwork".

This Dockerfile does not really package Seafile for Docker, but provides an environment for running it including startup scripts, including all dependencies for both a SQLite or MySQL (requires external MySQL database, for example in another container) setup.
Supports only 64bit systems.

## Setup

The image only prepares the base system and provides some support during installation. [Read through the setup manual](https://github.com/haiwen/seafile/wiki/Download-and-setup-seafile-server) before setting up Seafile.

Run the image in a container, exposing ports as needed and making `/seafile` permanent. For setting seafile up, maintaining its configuration or performing updates, make sure to start a shell. As the image builds on [`phusion/baseimage`](https://github.com/phusion/baseimage-docker), do so by attaching `-- /bin/bash` as parameter.


VER - actual ver (eg 6.0.7), or 'latest'

For example, you could use

    docker run -t -i \
      -e VER=latest \
      -e SERVER_NAME=seafile-server \
      -e SERVER_IP=ip \
      -e SEAHUB_ADMIN_USER=kala \
      -e SEAHUB_ADMIN_PW=kalakala \
      -v /path/on/host:/seafile \
      jenserat/seafile -- setup-seafile

Consider using a reverse proxy for using HTTPs.

In case you want to use memcached instead of /tmp/seahub_cache/ add the following to your seahub_settings.py

    CACHES = {
      'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': 'memcached:11211',
      }
    }

Link your memcached instance to your seafile container by adding `--link memcached_container:memcached` to your docker run statement.

## Running Seafile

Run the image again, this time you probably want to give it a name for using some startup scripts. You will not need an interactive shell for normal operation. **The image will autostart the `seafile` and `seahub` processes if the environment variable `AUTOSTART=true` is set.** A reasonable docker command is

    docker run -d \
      --name seafile \
      -p 10001:10001 \
      -p 12001:12001 \
      -p 8000:8000 \
      -p 8080:8080 \
      -p 8082:8082 \
      -v /path/on/host:/seafile \
      -e AUTOSTART=true \
      -e FASTCGI=true \
      jenserat/seafile

For proxying Seafile using nginx, enable FastCGI by adding `-e FASTCGI=true`.
Note: for cert other than self-signed, check https://letsencrypt.org/.

## Updates and Maintenance

The Seafile binaries are stored in the permanent volume `/seafile`. To update the base system, just stop and drop the container, update the image using `docker pull jenserat/seafile` and run it again. To update Seafile, follow the normal upgrade process described in the [Seafile upgrade manual](https://github.com/haiwen/seafile/wiki/Upgrading-Seafile-Server). `download-seafile` might help you with the first steps if already updated to the newest version.

## Workaround for [Seafile issue #478](https://github.com/haiwen/seafile/issues/478)

If used in FastCGI mode, like [recommended when proxying WebDAV](http://manual.seafile.com/extension/webdav.html#sample-configuration-2-with-nginxapache), seafdav only listens on `localhost:8080`; with consequence that it cannot be exposed. The image has a workaround built-in, which uses `socat` listening on `0.0.0.0:8080`, forwarding to `localhost:8081`. To use it, modify `/seafile/conf/seafdav.conf` and change the `port` to `8081`, and restart the container enabling the workaround using `-e WORKAROUND478=true`.
