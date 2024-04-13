#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    load) exec "$(dirname "$BASH_SOURCE")"/bbb/load.pl bbb "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    load HOST CMD...
EOF
    return 1
}

main "$@"
