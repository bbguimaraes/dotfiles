#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    clean) clean "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

clean() {
    rm -rf "$HOME/.ansible/cp/" "$HOME/.ansible/tmp/"
    rm -f "$HOME/.gnuplot_history"
    rm -f "$HOME/.msmtp.log"
    rm -f "$HOME/.units_history"
}

main "$@"
