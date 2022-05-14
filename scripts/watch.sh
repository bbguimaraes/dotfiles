#!/bin/bash
set -euo pipefail

main() {
    local cmd
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "${cmd-help}" in
    monitor) monitor "$@";;
    vim) vim "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

monitor() {
    inotifywait \
        --monitor --quiet \
        --format '%T %e %w %f' \
        --timefmt '%Y-%m-%dT%H:%M:%S' \
        "$@"
}

vim() {
    local f=4913
    inotifywait \
            --quiet --monitor --recursive \
            --event close_write --format %f . \
        | grep --line-buffered --line-regexp --invert-match "$f"
}

main "$@"
