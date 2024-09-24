#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    log) log "$@";;
    pop) pop "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    log
    pop
EOF
    return 1
}

log() {
    [[ "$#" -eq 0 ]] || usage
    local x
    for x in $(unfinished_ids); do
        tmux split-window -l 1000 tsp -c "$x"
    done
    exec tmux select-layout even-vertical
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

unfinished_ids() {
    tsp -l | awk '$2 == "running" { print $1 }'
}

main "$@"
