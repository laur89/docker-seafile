#!/bin/bash
# https://manual.seafile.com/deploy/using_sqlite.html
#
#
# Inspiration from following seafile dockers:
#   https://github.com/foxel/seafile-docker/blob/master/scripts/setup.sh

SEAFILE_PATH=''                       # will be defined later on
SEAFILE_URL="https://$SERVER_IP"      # note https (assuming you've enabled https)
SEAFILE_ROOT='/seafile'               # domain/{root} under which seafile will be served from
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
            | grep -o 'https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_.*x86-64.tar.gz' \
            | head -n1)" || exit 1

        readonly VER="$(grep -Po 'seafile-server_\K.*(?=_x8.*$)' <<< "$url")" || exit 1
        [[ "$VER" =~ $VER_REGEX ]] || fail "found latest ver was in unexpected format: [$VER]"
    else  # actual version number was specified:
        url="https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_${VER}_x86-64.tar.gz"
    fi

    readonly SEAFILE_PATH="/seafile/seafile-server-$VER"  # define installation dir

    # sanity:
    if [[ -e "$SEAFILE_PATH" ]]; then
        fail "[$SEAFILE_PATH] already exists; assuming [$VER] is already installed. abort."
    fi

    wget \
        --progress=dot:mega \
        --no-check-certificate \
        -O "$downloaded_tarball" \
        "$url" || fail "wgetting tarball from [$url] failed"

    mkdir -p -- "$SEAFILE_PATH" || exit 1
    tar -xzf "$downloaded_tarball" --strip-components=1 -C "$SEAFILE_PATH" || exit 1
    rm -- "$downloaded_tarball" || exit 1
}


# Taken from https://github.com/haiwen/seafile-server-installer-cn/blob/master/seafile-server-ubuntu-14-04-amd64-http
setup_seafile() {
    local init_admin init_admin_bak

    readonly init_admin="${SEAFILE_PATH}/check_init_admin.py"
    readonly init_admin_bak="${init_admin}.bak"

    check_is_file "$init_admin"
    # Backup check_init_admin.py befor applying changes
    cp -- "$init_admin" "$init_admin_bak" || exit 1

    sed --follow-symlinks -i 's/= ask_admin_email()/= '"\"${SEAHUB_ADMIN_USER}\""'/' "$init_admin" || exit 1
    sed --follow-symlinks -i 's/= ask_admin_password()/= '"\"${SEAHUB_ADMIN_PW}\""'/' "$init_admin" || exit 1

    "${SEAFILE_PATH}/setup-seafile.sh" auto || fail "seafile setup failed."

    # Start and stop Seafile eco system. This generates the initial admin user.
    "${SEAFILE_PATH}/seafile.sh" start || exit 1
    "${SEAFILE_PATH}/seahub.sh" start || exit 1
    "${SEAFILE_PATH}/seahub.sh" stop || exit 1
    "${SEAFILE_PATH}/seafile.sh" stop || exit 1

    # Restore original check_init_admin.py
    mv -- "$init_admin_bak" "$init_admin" || exit 1
}


# https://manual.seafile.com/extension/webdav.html
setup_webdav() {
    local f

    readonly f='./conf/seafdav.conf'

    check_is_file "$f"
    crudini --merge "$f" <<'EOF'
[WEBDAV]
enabled = true
port = 8080
host = $SERVER_IP
fastcgi = true
share_name = /seafdav
EOF
}


# https://manual.seafile.com/deploy/deploy_with_nginx.html
setup_ccnet_for_nginx() {
    local f

    readonly f='./conf/ccnet.conf'

    check_is_file "$f"
    crudini --set "$f" General SERVICE_URL "${SEAFILE_URL}$SEAFILE_ROOT"
}


# https://manual.seafile.com/deploy/deploy_with_nginx.html
# additional conf from:
#   https://manual.seafile.com/config/user_options.html
#   https://manual.seafile.com/config/seahub_settings_py.html
setup_seahub_settings_for_nginx() {
    local f

    readonly f='./conf/seahub_settings.py'

    check_is_file "$f"
    cat >> "$f" <<EOF
# first block is from and for: https://manual.seafile.com/deploy/deploy_seahub_at_non-root_domain.html
SERVE_STATIC = False
MEDIA_URL = '/seafmedia/'
COMPRESS_URL = MEDIA_URL
STATIC_URL = MEDIA_URL + 'assets/'
SITE_ROOT = '$SEAFILE_ROOT/'
LOGIN_URL = '$SEAFILE_ROOT/accounts/login/'

ENABLE_SIGNUP = False
ACTIVATE_AFTER_REGISTRATION = False
FILE_SERVER_ROOT = '${SEAFILE_URL}/seafhttp'
ENABLE_THUMBNAIL = True
EOF
}


check_is_file() {
    local file
    readonly file="$1"
    [[ -f "$file" ]] || fail "[$file] is not a valid file"
}


fail() {
    local msg
    readonly msg="$1"
    echo -e "\n\n    ERROR: $msg\n\n"
    exit 1
}


# Perform sanity:
if [[ -z "$VER" ]]; then
    fail "VER env var was not provided"
elif ! [[ "$VER" =~ $VER_REGEX || "$VER" == latest ]]; then
    fail "version was in unaccepted format: [$VER]"
fi

download_seafile
setup_seafile
setup_webdav
setup_ccnet_for_nginx
setup_seahub_settings_for_nginx

exit 0
