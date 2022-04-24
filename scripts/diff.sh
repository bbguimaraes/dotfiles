#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    sorted) sorted "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:

    sorted
EOF
    return 1
}

sorted() {
    local i s
    i=$(cat)
    s=$(sort <<< "$i")
    diff "$@" /dev/fd/2 /dev/fd/3 2<<< "$i" 3<<< "$s"
}

main "$@"
