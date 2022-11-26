#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && { console; return; }
    local cmd=$1; shift
    case "$cmd" in
    console) console "$@";;
    web) web "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD]

Commands:

    console
    web
EOF
    return 1
}

console() {
    if tty --quiet; then
        exec curl https://wttr.in/brno
    else
        exec "$TERMINAL" -e bash -c 'd weather; read -n 1'
    fi
}

web() {
    local l u
    l=2-3078610
    u=https://www.yr.no/en/content/$l/meteogram.svg
    curl --silent --show-error "$u" \
        | convert svg:- png:- \
        | feh --image-bg black -
}

main "$@"
