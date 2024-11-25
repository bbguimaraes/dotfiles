#!/bin/bash
set -euo pipefail

DIR=$HOME/musica

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    archive) archive "$@";;
    rnd) rnd "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    archive
    rnd [ARG...]
    rnd [album
EOF
    return 1
}

archive() {
    [[ "$#" -eq 0 ]] || usage
    cd "$DIR"
    find -type f -printf '%P\n' | sort | sponge ~/n/archivum/musica/musica.txt
}

rnd() {
    [[ "$#" -eq 0 ]] && rnd_args "$@"
    local cmd=$1; shift
    case "$cmd" in
    album) find "$DIR" -mindepth 2 -type d | shuf -n 1;;
    *) rnd_args "$cmd" "$@";;
    esac
}

rnd_args() {
    exec mpv --shuffle "$DIR" "$@"
}

main "$@"
