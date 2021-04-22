#!/bin/bash
set -euo pipefail

SCRIPTS=$HOME/n/comp/scripts/nngn
main() {
    local cmd=
    if [[ "$#" -gt 0 ]]; then
        cmd=$1
        shift
    fi
    case "$cmd" in
    check) subdir check.py "$@";;
    configure) subdir configure.sh "$@";;
    launcher) launcher;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

subdir() {
    local cmd=$1; shift
    exec "$(dirname "${BASH_SOURCE}")/nngn/$cmd" "$@"
}

launcher() {
    cd ~/src/nngn
    local p=tools/bin/launcher
    local t=/tmp/nngn/debug
    [[ -e "$t/$p" ]] && exec "$t/$p"
    t=$(find /tmp/nngn -mindepth 1 -maxdepth 1 -print -exit)
    [[ "$t" ]] && exec "$t/$p"
}

main "$@"
