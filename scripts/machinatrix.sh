#!/usr/bin/env bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    xclip) cmd_xclip "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    xclip CMD...
EOF
    return 1
}

cmd_xclip() {
    [[ "$#" -eq 0 ]] || usage
    local cmd
    cmd=$(dmenu -p 'cmd:' <<< '')
    d terminal bash -c \
        'machinatrix "$@" | xclip -selection clipboard; read' \
        bash $cmd
}

main "$@"
