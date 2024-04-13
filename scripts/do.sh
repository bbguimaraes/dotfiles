#!/bin/bash
set -euo pipefail

DIR=/tmp/do
CMD_FILE=$DIR/cmd.txt
FIFO=$DIR/fifo

main() {
    local cmd=shell
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    shell) shell;;
    cmd) cmd "$@";;
    watch) watch "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARG...]

Commands:

    shell
    cmd ARG...
    watch ARG...
EOF
    return 1
}

shell() {
    $SHELL "$CMD_FILE"
}

cmd() {
    mkdir -p "$DIR"
    echo "$@" > "$CMD_FILE"
}

watch() {
    mkdir -p "$DIR"
    [[ -e "$FIFO" ]] || mkfifo "$FIFO"
    cmd printf '\\x1' \> "$FIFO"
    while read -n 1 < "$FIFO"; do
        "$@" || true
    done
}

main "$@"
