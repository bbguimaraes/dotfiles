#!/bin/bash
set -euo pipefail

ADDR=192.168.0.4
PORT=2121
REQ_ARGS=(--user anonymous:)
ROOT=/storage/emulated/0

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    push) push "$@";;
    pull) pull "$@";;
    send) send "$@";;
    ls) cmd_ls "$@";;
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
    send audio FILES...
EOF
    return 1
}

send() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    audio) send_audio "$@";;
    *) usage;;
    esac
}

send_audio() {
    local x
    printf '%s\0' "$@" \
        | xargs --null --max-args 1 --max-procs 0 d video conv audio
    for x; do
        x=${x%.*}.ogg
        d phone push "$x"
        rm "$x"
    done
}

push() {
    local x
    for x; do
        echo "$x"
        curl "${REQ_ARGS[@]}" --upload-file "$x" "ftp://$ADDR:$PORT/$ROOT/"
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
        pull_file "$(url_for_file "$x")" -o "$(basename "$x")"
    done
}

pull_file() {
    request --ignore-content-length "${REQ_ARGS[@]}" "$@"
}

cmd_ls() {
    [[ "$#" -eq 0 ]] && set -- ''
    local x
    for x; do
        [[ "$x" ]] && echo "$x"
        request "${REQ_ARGS[@]}" "$(url_for_file "$x")"
    done
}

url_for_file() {
    echo "ftp://$ADDR:$PORT/$ROOT/$1"
}

request() {
    curl --silent --show-error "$@"
}

main "$@"
