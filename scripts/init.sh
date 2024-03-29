#!/bin/bash
set -euo pipefail

CMDS=(all keyboard)

main() {
    local cmd=all
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    all) cmd_all;;
    complete) cmd_complete;;
    keyboard) keyboard;;
    services) services;;
    work) work;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD]

Commands:

    all
    complete
    keyboard
    services
    work
EOF
    return 1
}

cmd_complete() {
    local line=($COMP_LINE)
    local n=${#line[@]}
    case "$n" in
    1) compgen -W "${CMDS[*]}";;
    2) compgen -W "${CMDS[*]}" "${line[$((n - 1))]}";;
    esac
}

cmd_all() {
    case "$HOSTNAME" in
    rh*) work;;
    *) pass show test > /dev/null;;
    esac
    init_temp
    keyboard
    services
}

work() {
    if ! ip link show tun0 > /dev/null ; then
        sudo /usr/local/bin/openvpn.sh redhat_brq.conf
        until ip link show tun0 > /dev/null; do sleep 0.5; done
    fi
    ~/rh/scripts/kinit.py bbarcaro
    pass show test > /dev/null
}

init_temp() {
    local f=$HOME/src/dotfiles/i3/status name
    name=$(ls /sys/devices/platform/coretemp.0/hwmon/ | head -n 1)
    grep --quiet "/$name/" "$f" && return
    sed --in-place "s/hwmon[0-9]\+/$name/" "$f"
    i3-msg restart
}

keyboard() {
    xset r rate 150 255
    setxkbmap -option compose:caps
}

services() {
    pgrep nextcloud > /dev/null || nextcloud &
    systemctl --user is-active --quiet redshift.service \
        || systemctl --user start redshift.service
    systemctl --user is-active --quiet vdirsyncer.service \
        || systemctl --user start vdirsyncer.service
}

main "$@"
