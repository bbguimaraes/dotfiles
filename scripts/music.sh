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
    rnd album [N]
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
    album) rnd_album "$@";;
    *) rnd_args "$cmd" "$@";;
    esac
}

rnd_args() {
    exec mpv --shuffle "$DIR" "$@"
}

rnd_album() {
    case "$#" in
    0) ;;
    1) set -- -n "$@";;
    *) usage;;
    esac
    find "$DIR" -mindepth 2 -type d | shuf "$@"
}

main "$@"
