#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    reload) reload;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:

    reload
EOF
    return 1
}

reload() {
    local w
    w=$(xdotool getactivewindow)
    xdotool \
        search --name --onlyvisible 'Mozilla Firefox' \
        windowactivate
    xdotool key ctrl+r
    xdotool windowactivate "$w"
}

main "$@"
