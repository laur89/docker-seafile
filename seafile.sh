#!/usr/bin/env bash

readonly LOG=/var/log/seafile.log
readonly SEAFILE_BIN=/seafile/seafile-server-latest/seafile.sh

stop_server() {
    sleep 2  # give chance for seahub to stop first

    pgrep -f 'seafile-controller|ccnet-server|seaf-server' | xargs kill
    #pkill -f seafile-controller
    exit 0
}

trap stop_server SIGINT SIGTERM
source /common.sh || { echo -e "    ERROR: failed to import /common.sh"; exit 1; }

[[ "$AUTOSTART" =~ ^[Tt]rue$ && -x "$SEAFILE_BIN" ]] || exit 0

wait_for_db
sleep 2

{
    echo '----------------------------------------'
    printf -- "--> launching seafile server at [%s]\n" "$(date)"
} >> "$LOG"
"$SEAFILE_BIN" start >> "$LOG" 2>&1

# wait for process to spin up:
sleep 5

# Script should not exit unless seafile died
while pgrep -f "seafile-controller" >/dev/null 2>&1; do
    sleep 5
done

exit 0
