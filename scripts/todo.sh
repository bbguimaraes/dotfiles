#!/usr/bin/env bash
set -euo pipefail

DIR=~/n/archivum/todo
DIES=(lunae martis mercurii iovis veneris saturnis solis)

main() {
    [[ "$#" -eq 0 ]] && { todo; return; }
    local cmd=$1; shift
    case "$cmd" in
    log) log "$@";;
    week) week "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARG...]

Commands:

    log
    week DAYS_AHEAD
EOF
    return 1
}

todo() {
    exec "$VISUAL" \
        -c "source $HOME/src/dotfiles/vim/todo.vim" \
        ~/n/todo.txt
}

log() {
    local log='journalctl --output short-iso'
    { $log --until today --lines 1 && $log --since today --lines +1; } \
        | sed --expression 's/^.*T//;s/ .*//'
}

week() {
    [[ "$#" -gt 1 ]] && usage
    local i offset today day
    offset=${1-0}
    today=$(date +%d --date "+${offset} days")
    day=$(<"$DIR/dies.txt")
    for i in {0..6}; do
        echo "- $((today + i)) ${DIES[i]}"
        sed 's/^/  /' <<< "$day"
    done
}

main "$@"
