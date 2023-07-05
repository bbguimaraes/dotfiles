#!/bin/bash
set -euo pipefail

YR_NO_URL=https://www.yr.no/en/content/2-3078610/meteogram.svg
YR_NO_PATH=/tmp/meteogram.svg

main() {
    [[ "$#" -eq 0 ]] && { console; return; }
    local cmd=$1; shift
    case "$cmd" in
    console) console "$@";;
    sync) sync "$@";;
    web) web "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD]

Commands:

    console
    sync
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

sync() {
    local d now
    if [[ -e "$YR_NO_PATH" ]]; then
        d=$(stat --format %Y "$YR_NO_PATH")
        now=$(date +%s)
        [[ $((now - d)) -lt 3600 ]] && return 0
    fi
    curl --silent --show-error "$YR_NO_URL" \
        | convert svg:- "png:$YR_NO_PATH"
}

web() {
    sync
    feh "$YR_NO_PATH"
}

main "$@"
