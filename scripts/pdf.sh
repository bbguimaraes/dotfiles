#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    split) split "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: pdf cmd

Commands:

    split images [args...]
EOF
    return 1
}

split() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    images) split_images "$@";;
    *) usage;;
    esac
}

split_images() {
    exec convert -verbose -density 150 -quality 100 -sharpen 0x1.0 "$@"
}

main "$@"
