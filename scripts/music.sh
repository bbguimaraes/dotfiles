#!/bin/bash
set -euo pipefail

DIR=$HOME/music

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    rnd) rnd "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

rnd() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    album) find "$DIR" -mindepth 2 -type d | shuf -n 1;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

main "$@"
