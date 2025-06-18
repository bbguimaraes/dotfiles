#!/usr/bin/env bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    generate) generate "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    generate N
EOF
    return 1
}

generate() {
    [[ "$#" -eq 1 ]] || usage
    < /dev/urandom \
        tr -cd '[:alnum:][:punct:]' \
        | head -c "$1"
    echo
}

main "$@"
