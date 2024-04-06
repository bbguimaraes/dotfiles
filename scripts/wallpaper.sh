#!/usr/bin/env bash
set -euo pipefail

LINK=$HOME/n/archivum/img/bg

main() {
    [[ "$#" -eq 0 ]] && { cmd_set; return; }
    local cmd=$1; shift
    case "$cmd" in
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARG...]
EOF
    return 1
}

cmd_set() {
    convert \
        -gravity center -background black \
        -resize '1920x1080>' -extent 1920x1080 \
        "$LINK" /tmp/bg.png
    feh --no-fehbg --bg-center "$LINK"
}

main "$@"
