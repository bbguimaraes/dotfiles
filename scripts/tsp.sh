#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    pop) pop "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    pop
EOF
    return 1
}

pop() {
    local i
    i=$(tsp -l | awk '$2 == "finished" { print $1; exit }')
    [[ "$i" ]] || return
    tsp -c "$i" || true
    tsp -r "$i"
}

main "$@"
