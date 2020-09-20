#!/usr/bin/env bash

check_is_file() {
    local file
    readonly file="$1"
    [[ -f "$file" ]] || fail "${FUNCNAME[1]}: [$file] is not a valid file"
}


check_dependencies() {
    local i

    for i in nc pgrep crudini; do
        command -v "$i" >/dev/null || fail "[$i] not installed"
    done
}


fail() {
    local msg
    readonly msg="$1"
    echo -e "\n\n    ERROR: $msg\n\n"
    exit 1
}


wait_for_db() {
    local host port

    __parse_db_connection_details() {
        local config

        readonly config='/seafile/conf/seafile.conf'

        check_is_file "$config"
        host="$(crudini --get "$config" database host)" || fail "fetching db host from config file [$config] failed"
        port="$(crudini --get "$config" database port)" || fail "fetching db port from config file [$config] failed"
        [[ -z "$host" || -z "$port" ]] && fail "couldn't parse either db hostname and/or port"
    }

    __parse_db_connection_details
    echo "Wait until database [$host:$port] is ready..."
    until nc -z "$host" "$port"; do
        sleep 2
    done

    return 0
}

check_dependencies
