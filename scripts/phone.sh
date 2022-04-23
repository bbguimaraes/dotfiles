#!/bin/bash
set -euo pipefail

ADDR=192.168.0.5
PORT=2121
ARGS=(--user anonymous:)
ROOT=/storage/emulated/0

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    push) push "$@";;
    pull) pull "$@";;
    ls) _ls "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARGS...

Commands:

    push FILES...
    pull FILES...
    ls PATHS...
EOF
    return 1
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
