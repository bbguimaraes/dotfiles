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
    rm -rf "$HOME/.cargo/"
    rm -rf "$HOME/.config/chromium/Default/Service Worker/CacheStorage/"
    rm -f "$HOME/.gnuplot_history"
    rm -rf "$HOME/.kube/cache/"
    rm -f "$HOME/.units_history"
    [[ -d "$HOME/go" ]] && chmod --recursive 777 "$HOME/go/"
    rm -rf "$HOME/go/"
}

main "$@"
