#!/bin/bash

readonly LOG=/var/log/seafile.log

function stop_server() {
    #ps ax | grep run_gunicorn | awk '{ print $1 }' | xargs kill
    pgrep -f run_gunicorn | xargs kill
    exit 0
}

trap stop_server SIGINT SIGTERM

[[ "$AUTOSTART" =~ [Tt]rue && -x /seafile/seafile-server-latest/seahub.sh ]] || exit 0

if [[ "$FASTCGI" =~ [Tt]rue ]]; then
    SEAFILE_FASTCGI_HOST='0.0.0.0' /seafile/seafile-server-latest/seahub.sh start-fastcgi >> "$LOG"
else
    /seafile/seafile-server-latest/seahub.sh start >> "$LOG" 2>&1
fi

# Script should not exit unless seahub died
while pgrep -f "manage.py run_gunicorn" >/dev/null 2>&1; do
    sleep 5
done

exit 0
