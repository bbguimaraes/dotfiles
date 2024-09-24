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
    local i f
    i=$(finished_ids | head -1)
    [[ "$i" ]] || return
    f=$(tsp -o "$i")
    cat "$f"
    tsp -r "$i"
}

finished_ids() {
    tsp -l | awk '$2 == "finished" { print $1 }'
}

main "$@"
