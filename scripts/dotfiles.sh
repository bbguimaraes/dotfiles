#!/bin/bash
set -euo pipefail

CMDS=(complete pull)

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    complete) cmd_complete "$@";;
    pull) pull "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    pull
EOF
    return 1
}

cmd_complete() {
    local line=($COMP_LINE)
    local n=${#line[@]}
    case "$n" in
    1) compgen -W "${CMDS[*]}";;
    2) compgen -W "${CMDS[*]}" "${line[$((n - 1))]}";;
    esac
}

pull() {
    cd ~/src/dotfiles
    git stash push
    git fetch --all
    git rebase origin/master master
    [[ "$(git stash list)" ]] && git stash pop || :
}

main "$@"
