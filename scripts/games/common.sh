#!/bin/bash

COMMON_USER=bbguimaraes
COMMON_PULSE_SERVER=/tmp/pa.sock
COMMON_XHOST_ERR=$(cat <<'EOF'
missing X access control rule, create with:

xhost "+si:localuser:%s"
EOF
)
COMMON_PULSE_ERR=$(cat <<'EOF'
missing pulseaudio socket, create with:

pactl load-module module-native-protocol-unix \
    auth-anonymous=true auth-group-enable=false auth-cookie-enabled=false \
    socket=%s
EOF
)

common_exec() {
    local dir=$1; shift
    systemd-nspawn -D "$dir" "$@"
}

common_install() {
    local dir=$1 uid; shift
    uid=$(awk < "/etc/passwd" -F : -v u="$COMMON_USER" '$1==u{print$3}')
    pacstrap -ic "$dir" --noconfirm --needed "$@"
    common_exec "$dir" groupmod --gid 100 users
    if
        ! < "$dir/etc/passwd" \
        cut --delimiter : --fields 1 \
        | grep --quiet --line-regexp "$COMMON_USER"
    then
        common_exec "$dir" \
            useradd --uid "$uid" --gid 100 --create-home "$COMMON_USER"
    fi
}

common_shell() {
    local dir=$1; shift
    if
        ! runuser -u "$COMMON_USER" xhost \
        | grep --quiet --line-regexp "SI:localuser:$COMMON_USER"
    then
        printf >&2 "$COMMON_XHOST_ERR\n" "$COMMON_USER"
        return 1
    fi
    if ! [[ -e "$COMMON_PULSE_SERVER" ]]; then
        printf >&2 "$COMMON_PULSE_ERR\n" "$COMMON_PULSE_SERVER"
        return 1
    fi
    common_exec "$dir" \
        --bind /tmp/.X11-unix \
        --bind /dev/dri \
        --bind /dev/input \
        --bind /tmp/pa.sock \
        --bind /home/"$COMMON_USER"/.Xauthority \
        --setenv DISPLAY=:0 \
        --setenv PULSE_SERVER=/tmp/pa.sock \
        --property DeviceAllow='char-drm rw' \
        --chdir /home/"$COMMON_USER" \
        --user "$COMMON_USER" \
        "$@"
}
