#!/bin/bash

readonly LOG=/var/log/seafile.log

function stop_server() {
    pkill -f seahub
    #pgrep -f seahub | xargs kill
    exit 0
}

trap stop_server SIGINT SIGTERM

[[ "$AUTOSTART" =~ [Tt]rue && -x /seafile/seafile-server-latest/seahub.sh ]] || exit 0

# wait for seafile server to start:
sleep 5

{
    echo '----------------------------------------'
    printf -- "--> launching seahub at [%s]\n" "$(date)"
} >> "$LOG"
SEAFILE_FASTCGI_HOST='0.0.0.0' /seafile/seafile-server-latest/seahub.sh start-fastcgi >> "$LOG"

# wait for process to spin up:
sleep 5

# Script should not exit unless seahub died
while pgrep -f "seahub" >/dev/null 2>&1; do
    sleep 5
done

exit 0
