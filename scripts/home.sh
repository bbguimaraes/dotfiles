#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    clean) clean "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:

    clean
EOF
    return 1
}

clean() {
    rm -rf "$HOME/.ansible/cp/" "$HOME/.ansible/tmp/"
    rm -f "$HOME/.gnuplot_history"
    rm -f "$HOME/.msmtp.log"
    rm -f "$HOME/.units_history"
}

main "$@"
