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
    check) check "$@";;
    configure) exec "$SCRIPTS/configure.sh" $@;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

check() {
    local build_dir=$1; shift
    make -C "$build_dir" "$@" all check-programs
    make -C "$build_dir" check "$@" || cat "$build_dir/test-suite.log"
}

main "$@"
