#!/usr/bin/env bash

readonly LOG=/var/log/seahub.log
readonly PROCESS_NAME='seahub.wsgi:application'
readonly SEAHUB_BIN=/seafile/seafile-server-latest/seahub.sh

# TODO: should we kill via pid-files instead?
stop_server() {
    #"$SEAHUB_BIN" stop >> "$LOG"  # TODO: shouldn't we do this?
    #sleep 5

    pkill -f "$PROCESS_NAME"
    #pgrep -f seahub | xargs kill
    exit 0
}

trap stop_server SIGINT SIGTERM
source /common.sh || { echo -e "    ERROR: failed to import /common.sh"; exit 1; }

[[ "$AUTOSTART" =~ ^[Tt]rue$ && -x "$SEAHUB_BIN" ]] || exit 0

wait_for_db

# wait for seafile server to start:
sleep 5

{
    echo '----------------------------------------'
    printf -- "--> launching seahub at [%s]\n" "$(date)"
} >> "$LOG"
"$SEAHUB_BIN" start >> "$LOG"

# wait for process to spin up:
sleep 5

# Script should not exit unless seahub died
#while pgrep -f seahub >/dev/null 2>&1; do
while pgrep -f "$PROCESS_NAME" >/dev/null 2>&1; do
    sleep 5
done

exit 0
