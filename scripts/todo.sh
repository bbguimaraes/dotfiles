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
    local date="+${1-0} days" today
    today=$(date +%e --date "$date")
    week_day "$today"
    week_week "$date"
}

week_day() {
    local today=$1 day=$(<"$DIR/dies.txt") i
    for i in {0..6}; do
        printf -- '- %02d %s\n' "$((today + i))" "${DIES[i]}"
        sed 's/^/  /' <<< "$day"
    done
}

week_week() {
    local week
    week=$(date +%W --date "$1")
    echo "- h${week}"
    sed 's/^/  /' "$DIR/hebdomadas.txt"
}

main "$@"
