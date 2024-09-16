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
    editor DIR
    shell DIR
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
    tmux rename-window "$name"
    tmux split-window d ws shell "$dir"
    tmux select-layout main-vertical
    cmd_editor "$dir"
}

cmd_editor() {
    [[ "$#" -eq 1 ]] || usage
    local dir=$1 cmd=(vim)
    dir=$(dir "$dir")
    [[ -e "$dir/.git" ]] && cmd=("${cmd[@]}" -c 'call GitTab()')
    eval "$(d cd "$dir")"
    cd "$dir"
    exec "${cmd[@]}"
}

cmd_shell() {
    [[ "$#" -eq 1 ]] || usage
    local dir=$1 cmd=(bash -i)
    dir=$(dir "$dir")
    if [[ -e "$dir/.git" ]]; then
        git -C "$dir" branch
        git -C "$dir" status
    fi
    eval "$(d cd "$dir")"
    cd "$dir"
    exec "${cmd[@]}"
}

main "$@"
