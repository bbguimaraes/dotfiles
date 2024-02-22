#!/bin/bash
set -euo pipefail

DIR=$HOME/musica

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    rnd) rnd "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARGS...

Commands:

    rnd album
EOF
    return 1
}

rnd() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    album) find "$DIR" -mindepth 2 -type d | shuf -n 1;;
    *) usage;;
    esac
}

main "$@"
