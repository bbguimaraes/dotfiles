#!/bin/bash
set -euo pipefail

DEFAULT_DIR=$HOME/src

main() {
    [[ "$#" -gt 0 ]] || { echo >&2 "Usage: $0 dir"; return 1; }
    dir=$1
    case "$dir" in
    complete) cmd_complete;;
    *) cmd_ws "$@";;
    esac
}

cmd_complete() {
    local line=($COMP_LINE)
    local n=${#line[@]}
    case "$n" in
    1) compgen -W "$(ls "$DEFAULT_DIR")";;
    2) compgen -W "$(ls "$DEFAULT_DIR")" "${line[$((n - 1))]}";;
    esac
}

cmd_ws() {
    [[ -e "$dir" ]] || dir=$DEFAULT_DIR/$dir
    name=${1##*/}
    cd "$dir"
    tmux rename-window "$name"
    tmux split-window -c "$dir" 'git branch; git status; exec bash -i'
    tmux select-layout main-vertical
    sleep 1
    exec vim
}

main "$@"
