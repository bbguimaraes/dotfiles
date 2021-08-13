#!/bin/bash
set -euo pipefail

ADDR=192.168.0.5
PORT=2121
ARGS=(--user anonymous:)
ROOT=/storage/emulated/0

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=${1:-}; shift; }
    case "$cmd" in
    push) push "$@";;
    pull) pull "$@";;
    ls) _ls "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;
    esac
}

push() {
    local x
    for x; do
        echo "$x"
        curl "${ARGS[@]}" --upload-file "$x" "ftp://$ADDR:$PORT/$ROOT/"
    done
}

pull() {
    local x
    for x; do
        x=$(basename "$x")
        if [[ -e "$x" ]]; then
            echo >&2 "file exists, not overwriting: $x"
            return 1
        fi
    done
    for x; do
        echo "$x"
        curl --ignore-content-length "${ARGS[@]}" "ftp://$ADDR:$PORT/$ROOT/$x" -o "$(basename "$x")"
    done
}

_ls() {
    [[ "$#" -eq 0 ]] && set -- ''
    local x
    for x; do
        [[ "$x" ]] && echo "$x"
        curl "${ARGS[@]}" "ftp://$ADDR:$PORT/$ROOT/$x"
    done
}

main "$@"
