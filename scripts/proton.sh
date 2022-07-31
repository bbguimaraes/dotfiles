#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    token) token "$@";;
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

main "$@"
