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
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

subdir() {
    local cmd=$1; shift
    exec "$(dirname "${BASH_SOURCE}")/nngn/$cmd" "$@"
}

main "$@"
