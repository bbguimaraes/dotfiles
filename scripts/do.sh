#!/bin/bash
set -euo pipefail

DIR=/tmp/do
CMD_FILE=$DIR/cmd.txt
FIFO=$DIR/fifo

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    '') shell;;
    cmd) cmd "$@";;
    watch) watch "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;
    esac
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
        "$SHELL" -c "$*" || true
    done
}

main "$@"
