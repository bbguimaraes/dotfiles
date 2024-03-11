#!/usr/bin/env bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && { todo; return; }
    local cmd=$1; shift
    case "$cmd" in
    log) log "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARGS...]

Commands:

    log
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

main "$@"
