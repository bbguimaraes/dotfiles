#!/usr/bin/env bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    services) services "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    services start|stop
EOF
    return 1
}

services() {
    local l=(
        vdirsyncer.service
        mbsync@bbguimaraes.service
        offlineimap@dds.service
        proton-bridge.service
    )
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    start|stop) ;;
    *) usage;;
    esac
    systemctl --user "$cmd" "${l[@]}"
}

main "$@"
