#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    reload) reload;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
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
