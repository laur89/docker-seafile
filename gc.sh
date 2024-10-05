#!/usr/bin/env bash
#

seaf_running() {
    pgrep -f 'seafile-controller|seaf-server' > /dev/null
}


source /common.sh || { echo -e "    ERROR: failed to import /common.sh"; exit 1; }

is_autostart && fail "AUTOSTART=${AUTOSTART}, cannot run GC"
seaf_running && fail "seafile running, cannot run GC"


# first nuke the webdav temp files at least 2d old, see https://forum.seafile.com/t/cleanup-webdavtmp-files/15647/3 :
webdav_tmp_dir='/seafile/seafile-data/webdavtmp/'
if [[ -d "$webdav_tmp_dir" ]]; then
    find "$webdav_tmp_dir" -type f -mtime +2 -delete || err "webdavtmp file find-delete failed w/ $?"
else
    err "[$webdav_tmp_dir] not a dir"
fi

# ...then execute GC; see https://github.com/laur89/docker-seafile?tab=readme-ov-file#gc
gc='/seafile/seafile-server-latest/seaf-gc.sh'
"$gc"  --dry-run || exit 1
"$gc"            || exit 1
"$gc"  -r        || exit 1
"$gc"  --rm-fs   || exit 1

exit 0
