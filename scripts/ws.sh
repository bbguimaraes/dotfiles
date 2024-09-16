#!/bin/bash
set -euo pipefail

DEFAULT_DIR=$HOME/src

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    complete) cmd_complete;;
    *) cmd_ws "$cmd" "$@";;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 DIR|CMD

Commands:

    complete
EOF
    return 1
}

dir() {
    local ret=$1
    [[ ! -e "$ret" && -e "$DEFAULT_DIR/$ret" ]] && ret=$DEFAULT_DIR/$ret
    echo "$ret"
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
    local dir=$1
    local name=${dir##*/}
    dir=$(dir "$dir")
    local cmd=(vim)
    [[ -e "$dir/.git" ]] && cmd=("${cmd[@]}" -c 'call GitTab()')
    eval "$(d cd "$dir")"
    tmux rename-window "$name"
    tmux split-window -c "$dir" "$(printf '%s;' \
        "eval \"\$(d cd "$dir")\"" \
        'git branch' 'git status' 'exec bash -i')"
    tmux select-layout main-vertical
    cd "$dir"
    sleep 1
    exec "${cmd[@]}"
}

main "$@"
