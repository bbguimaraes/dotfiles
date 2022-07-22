#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && custos
    local cmd=$1; shift
    case "$cmd" in
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:

EOF
    return 1
}

custos() {
    exec custos \
        --clear \
        --modules load,thermal,date
}

main "$@"
