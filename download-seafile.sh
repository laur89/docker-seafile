#!/usr/bin/env bash
#
# Inspiration from following seafile dockers:
#   https://github.com/foxel/seafile-docker/blob/master/scripts/setup.sh

SEAFILE_PATH=''                       # will be defined later on, as it depends on the seafile version
VER_REGEX='^[0-9]+\.[0-9]+\.[0-9]+$'  # seafile version validation regex


# 1) downloads tarball (either the latest or specified ver, depending on $VER);
# 2) defines $SEAFILE_PATH pointing to active installation directory;
# 3) untars downloaded tarball into $SEAFILE_PATH.
download_seafile() {
    local downloaded_tarball url

    readonly downloaded_tarball='/tmp/seafile-server.tar.gz'

    if [[ "$VER" == latest ]]; then
        url="$(wget \
            --progress=dot:mega \
            --no-check-certificate \
            "https://www.seafile.com/en/download/" -O- \
            | grep -o 'https://.*/seafile-server_.*x86-64.tar.gz' \
            | head -n1)" || exit 1

        readonly VER="$(grep -Po 'seafile-server_\K.*(?=_x8.*$)' <<< "$url")" || fail "unable to parse latest version from url [$url]"
        [[ "$VER" =~ $VER_REGEX ]] || fail "found latest ver was in unexpected format: [$VER]"
    else  # actual version number was specified:
        url="https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_${VER}_x86-64.tar.gz"
    fi

    readonly SEAFILE_PATH="/seafile/seafile-server-$VER"  # define installation dir

    # sanity:
    [[ -e "$SEAFILE_PATH" ]] && fail "[$SEAFILE_PATH] already exists; assuming [$VER] is already installed. abort."

    wget \
        --progress=dot:mega \
        --no-check-certificate \
        -O "$downloaded_tarball" \
        "$url" || fail "wgetting tarball from [$url] failed"

    mkdir -p -- "$SEAFILE_PATH" || exit 1
    tar -xzf "$downloaded_tarball" --strip-components=1 -C "$SEAFILE_PATH" || exit 1
    rm -- "$downloaded_tarball" || exit 1
}


source /common.sh || { echo -e "    ERROR: failed to import /common.sh"; exit 1; }

# Perform sanity:
if [[ -z "$VER" ]]; then
    fail "VER env var was not provided"
elif ! [[ "$VER" =~ $VER_REGEX || "$VER" == latest ]]; then
    fail "version was in unaccepted format: [$VER]"
fi

download_seafile

exit 0
