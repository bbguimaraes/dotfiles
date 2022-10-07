#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    token) token "$@";;
    pw) pw "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:

    token
EOF
    return 1
}

stop() {
    systemctl --user stop proton-bridge.service
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
