#!/bin/bash
set -euo pipefail

SCRIPTS=$HOME/n/comp/scripts/nngn

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    check) subdir nngn.py check "$@";;
    configure) subdir nngn.py configure "$@";;
    launcher) launcher;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARGS...

Commands:

    check DIR CHECKS [-- CONFIGURE_ARGS...]
    configure DIR CHECKS [-- CONFIGURE_ARGS...]
    launcher
EOF
    return 1
}

subdir() {
    local cmd=$1; shift
    exec "$(dirname "${BASH_SOURCE}")/nngn/$cmd" "$@"
}

launcher() {
    cd ~/src/nngn
    local p=tools/bin/launcher
    local t=/tmp/nngn/debug
    [[ -e "$t/$p" ]] && exec "$t/$p" "$PWD/sock"
    t=$(find /tmp/nngn -mindepth 1 -maxdepth 1 -print -quit)
    [[ "$t" ]] && exec "$t/$p" "$PWD/sock"
}

main "$@"
