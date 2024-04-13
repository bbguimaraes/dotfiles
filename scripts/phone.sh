#!/bin/bash
set -euo pipefail

ADDR=192.168.0.4
PORT=2121
REQ_ARGS=(--user anonymous:)
ROOT=/storage/emulated/0
CAMERA=DCIM/Camera

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    addr) set_addr "$@";;
    camera) camera "$@";;
    push) push "ftp://$ADDR:$PORT/$ROOT/" "$@";;
    pull) pull "$@";;
    send) send "$@";;
    ls) cmd_ls "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    addr IP_ADDR
    [camera] ls PATH...
    [camera] push PATH...
    [camera] pull PATH...
    send audio FILE...
EOF
    return 1
}

set_addr() {
    [[ "$#" -ne 1 ]] && usage
    local addr=$1
    sed --in-place 's/^\(ADDR=\).*$/\1'"$addr"'/' "$BASH_SOURCE"
}

camera() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    ls) camera_ls "$@";;
    pull) camera_pull "$@";;
    push) camera_push "$@";;
    *) usage;;
    esac
}

camera_ls() {
    [[ "$#" -eq 0 ]] && set ''
    local x
    for x; do
        cmd_ls "DCIM/Camera/$x"
    done
}

camera_pull() {
    local d=$CAMERA l x
    if [[ "$#" -eq 0 ]]; then
        l=$(request --list-only "$(url_for_file "$d/")")
        IFS=$'\n' set $l
    fi
    for x; do
        echo "$x"
        pull_file "$(url_for_file "$d/$x")" -o "$x"
    done
}

camera_push() {
    push "ftp://$ADDR:$PORT/$ROOT/$CAMERA" "$@"
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
    local dst=$1 x; shift
    for src; do
        echo "$src"
        curl "${REQ_ARGS[@]}" --upload-file "$src" "$dst"
    done
}

pull() {
    local x
    for x; do
        echo "$x"
        pull_file "$(url_for_file "$x")" -o "$(basename "$x")"
    done
}

pull_file() {
    curl "${REQ_ARGS[@]}" --continue-at - "$@"
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
