#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    date) cmd_date "$@";;
    *) usage
    esac
}

usage() {
    cat <<EOF
Usage: $0 CMD ARG...

Commands:

    date FILE...
EOF
    return 1
}

cmd_date() {
    [[ "$#" -eq 0 ]] && usage
    local x date name
    for x; do
        date=$(identify -format '%[date:create]' "$x")
        name=$(date --utc +"%Y%m%d_%H%M%S")
        echo "$name"
    done
}

main "$@"
