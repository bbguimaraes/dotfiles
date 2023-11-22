#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    bridge) bridge "$@";;
    token) token "$@";;
    pw) pw "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:

    bridge start|stop
    token
EOF
    return 1
}

bridge() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    start) start;;
    stop) stop;;
    *) usage;;
    esac
}

stop() {
    local name=proton-bridge
    systemctl --user stop proton-bridge.service
    pkill --full "$name" || ! pgrep --full "$name"
    pkill "$name" || ! pgrep "$name"
    rm --force .cache/protonmail/bridge-v3/bridge-v3.lock
}

start() {
    systemctl --user start proton-bridge.service
}

token() {
    stop
    proton-bridge --cli <<EOF
login
bbguimaraes
$(pass show comp/protonmail/pw)
EOF
    start
}

pw() {
    local pw
    stop
    pw=$(proton-bridge --cli <<< info | awk '/^Password:/{print$2}')
    pass insert --force comp/protonmail/bridge <<< "$pw"
    start
}

main "$@"
