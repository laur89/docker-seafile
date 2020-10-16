# Seafile for Docker

## This version is good 'til v7.0.x; for v7.1+, please use newer version/tag!

[Seafile](http://www.seafile.com/) is a "next-generation open source cloud storage
with advanced features on file syncing, privacy protection and teamwork".

This Dockerfile does not really package Seafile for Docker, but provides an environment
for running it including startup scripts + all dependencies for using MySQL and
memcached.

Note this version provides only with MySQL-backed installation (not SQLite). Both db
and memcache instances are expected to be created before seafile is set up.
Also note this installation of seafile is expected to be ran behind a reverse proxy
over https. An example of nginx config that could be used is included.

## Setup

### MySql/Mariadb

Assumes accessible mysql/maria db is already installed.

Log in to the docker/machine hosting the database and create the user & databases:
(from https://github.com/foxel/seafile-docker/blob/master/scripts/setup.sh)

```
mysql -uroot -p${DB_ROOT_PW} <<'EOF'
DROP DATABASE IF EXISTS `ccnet_db`;
DROP DATABASE IF EXISTS `seafile_db`;
DROP DATABASE IF EXISTS `seahub_db`;
CREATE DATABASE `ccnet_db` CHARACTER SET = 'utf8';
CREATE DATABASE `seafile_db` CHARACTER SET = 'utf8';
CREATE DATABASE `seahub_db` CHARACTER SET = 'utf8';
DROP USER IF EXISTS 'seafile'@'%';
CREATE USER IF NOT EXISTS 'seafile'@'%' IDENTIFIED BY 'seafile_passwd';
GRANT ALL PRIVILEGES ON `ccnet_db`.* TO `seafile`@'%';
GRANT ALL PRIVILEGES ON `seafile_db`.* TO `seafile`@'%';
GRANT ALL PRIVILEGES ON `seahub_db`.* TO `seafile`@'%';
FLUSH PRIVILEGES;
EOF
```

Note you need to link seafile docker to the mariadb/mysql docker by `--link`ing it.

### Seafile

The embedded `setup-seafile` script is executed when running the image for the
first time, which installs & sets up seafile under `/seafile`.
[Reading through the setup manual](https://github.com/haiwen/seafile/wiki/Download-and-setup-seafile-server)
before setting up Seafile is still recommended, since there are more configuration
options that can be used and could be considered.
If you're using this docker on unraid, this means running the `docker run` command
below from command line, not from template.

Run the image in a container, exposing ports as needed and making `/seafile` volume permanent:

* `VER`: actual seafile server ver (eg `6.0.7`), or `latest`
* `SERVER_IP`: domain or IP of the box where seafile is set up; without the protocol

For example, you could use following command to install & setup (note the db data must
match the one you used when creating the db tables & users)

    docker run -it --rm \
      -e VER=6.0.7 \
      -e SERVER_NAME=seafile-server \
      -e SERVER_IP=seafile.yourdomain.com \
      -e FILESERVER_PORT=8082 \
      -e SEAHUB_ADMIN_USER=youradminuser \
      -e SEAHUB_ADMIN_PW=yourpassword \
      -e USE_EXISTING_DB=1 \
      -e MYSQL_HOST=db \
      -e MYSQL_PORT=3306 \
      -e MYSQL_USER=seafile \
      -e MYSQL_USER_PASSWD=seafile_passwd \
      -e CCNET_DB=ccnet_db \
      -e SEAFILE_DB=seafile_db \
      -e SEAHUB_DB=seahub_db \
      -e AUTOSTART=false \
      -v /path/on/host/to-installation-dir:/seafile \
      --link memcached \
      --link db \
      layr/seafile -- setup-seafile

Note the memcached instance is linked to your seafile container by adding
`--link memcached_container:memcached` to your docker run statement.
(or use [user defined networks](https://docs.docker.com/engine/userguide/networking/work-with-networks/#linking-containers-in-user-defined-networks)
instead, as `--link` option is now deprecated)

### Upgrade

Running following will simply download the required version and unpack it under
`/seafile`; you'll still want to follow upgrade notes afterwards (see below);
note `VER` value constraints/expectations as described above.

    docker run -it --rm \
      -e VER=6.0.7 \
      -e AUTOSTART=false \
      -v /path/on/host/to-installation-dir:/seafile \
      layr/seafile -- download-seafile

## Running Seafile

Run the image again, this time you probably want to give it a name for using some
startup scripts.
**The image will autostart the `seafile` and `seahub` processes if the environment
variable `AUTOSTART=true` is set.** A reasonable docker command would be

    docker run -d \
      --name seafile \
      -p 10001:10001 \
      -p 12001:12001 \
      -p 8000:8000 \
      -p 8080:8080 \
      -p 8082:8082 \
      -v /path/on/host/to-installation-dir:/seafile \
      -e AUTOSTART=true \
      --link memcached \
      --link db \
      layr/seafile

For unraid users: this is the command that should to be converted into a Docker template.

## Updates and Maintenance

The Seafile binaries are stored in the permanent volume `/seafile`. To update the
base system, just stop and drop the container, update the image using
`docker pull layr/seafile` and run it again. To update Seafile, follow the normal
upgrade process described in the [Seafile upgrade manual](https://download.seafile.com/published/seafile-manual/backup/upgrade/upgrade.md)
and/or ~[seafile gitbook](https://seafile.gitbook.io/seafile-server-manual/deploying-seafile-under-linux/upgrade-seafile-server)~
and/or [community docs](https://seafile.readthedocs.io/en/latest)

General steps:
- stop seafile server
- if using unraid, make sure you set env var `AUTOSTART=false`
- upgrade the image version if needed (if deps have changed that is)
- start server (w/ AUTOSTART=false!)
- open shell into container
- download new seafile version using included `download-seafile` script as shown above, eg (while in container shell):
  - export VER=latest
  - download-seafile
  - cd /seafile/seafile-server-7.1.5  (assuming you just downloaded v 7.1.5)
  - run the migration scripts as instructed by the manual
- run migration scripts/update configs as per [upgrade manual](https://download.seafile.com/published/seafile-manual/upgrade/upgrade.md)
- set `AUTOSTART=true` again
- restart container
- once all confirmed good - remove the old seafile installation dir from /seafile

## Backup & Recovery

See [here](https://download.seafile.com/published/seafile-manual/docker/deploy%20seafile%20with%20docker.md)

