#!/usr/bin/env bash
#
# For reference see https://github.com/haiwen/seafile-docker/blob/master/scripts/scripts_12.0/gc.sh
#
#readonly SEAFILE_BIN=/seafile/seafile-server-latest/seafile.sh
readonly GC_BIN=/seafile/seafile-server-latest/seaf-gc.sh

# perhaps also verify /pids/ dir is empty? although currently it's not properly
# cleaned up: https://github.com/haiwen/seafile/issues/2831
seaf_running() {
    local i

    i="$(sv status seafile)"
    [[ "$i" =~ ^down: ]] || return 0  # any other status than 'down', consider running

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
"$GC_BIN"  --dry-run || exit $?
"$GC_BIN"            || exit $?
sleep 1
"$GC_BIN"  -r        || exit $?
sleep 1
"$GC_BIN"  --rm-fs   || exit $?

exit 0
