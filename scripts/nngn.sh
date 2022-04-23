#!/bin/bash
set -euo pipefail

SCRIPTS=$HOME/n/comp/scripts/nngn

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    check) subdir nngn.py check "$@";;
    configure) subdir nngn.py configure "$@";;
    launcher) launcher;;
    plot) plot "$@";;
    wasm) wasm "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    check DIR CHECK [-- CONFIGURE_ARG...]
    configure DIR CHECK [-- CONFIGURE_ARG...]
    launcher
    plot time
    wasm server
EOF
    return 1
}

subdir() {
    local cmd=$1; shift
    exec "$(dirname "${BASH_SOURCE}")/nngn/$cmd" "$@"
}

launcher() {
    cd ~/src/nngn
    local p=tools/bin/launcher
    local t=/tmp/nngn/debug
    [[ -e "$t/$p" ]] && exec "$t/$p" "$PWD/sock"
    t=$(find /tmp/nngn -wholename "*/$p" -print -quit)
    [[ "$t" ]] && exec "$t" "$PWD/sock"
}

plot() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    time) plot_time "$@";;
    *) usage;;
    esac
}

plot_time() {
    { echo g l; ts $'f %s\nd l'; } | nngn_plot
}

wasm() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    server) wasm_server "$@";;
    *) usage;;
    esac
}

wasm_server() {
    cd ~/src/nngn
    emrun --port 8000 --no_browser nngn.html
}

main "$@"
