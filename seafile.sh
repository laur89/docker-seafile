#!/bin/bash

readonly LOG=/var/log/seafile.log

function stop_server() {
    pgrep -f 'seafile-controller|ccnet-server|seaf-server' | xargs kill
    #kill $( ps ax | grep -E 'seafile-controller|ccnet-server|seaf-server' | grep -v grep | awk '{ print $1 }' | xargs )
    exit 0
}

trap stop_server SIGINT SIGTERM

[[ "$AUTOSTART" =~ ^[Tt]rue && -x /seafile/seafile-server-latest/seafile.sh ]] || exit 0

# Fix for https://github.com/haiwen/seafile/issues/478, forward seafdav localhost-only port
[[ "$WORKAROUND478" =~ [Tt]rue ]] && socat TCP4-LISTEN:8080,fork TCP4:localhost:8081 &

/seafile/seafile-server-latest/seafile.sh start >> "$LOG" 2>&1

# Script should not exit unless seafile died
while pgrep -f "seafile-controller" >/dev/null 2>&1; do
    sleep 5
done

exit 0
