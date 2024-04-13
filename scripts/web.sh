#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    [[ "$#" -eq 1 ]] && { terminal d web lynx "$@"; return; }
    local cmd=$1; shift
    case "$cmd" in
    ddg) ddg "$@";;
    lynx) lynx "$@";;
    priv) exec firefox --private-window "$@";;
    vim) cmd_vim "$@";;
    wikt) wikt "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD [ARG...]

Commands:

    URL
    ddg|wikt QUERY...
    lynx [ARG...]
    vim URL
EOF
    return 1
}

lynx() {
    command lynx \
        --display-charset utf-8 \
        --collapse-br-tags \
        --cookies \
        "$@"
}

terminal() {
    local cmd=("$@")
    tty --quiet || cmd=("$TERMINAL" -e "${cmd[@]}")
    "${cmd[@]}"
}

ddg() {
    local IFS=+
    lynx "https://html.duckduckgo.com/html?q=$*"
}

cmd_vim() {
    local html
    html=$(lynx --dump "$1")
    terminal bash -c 'vim - <<< $1' bash "$html"
}

wikt() {
    local IFS=+
    lynx "https://en.wiktionary.org/wiki/$*"
}

main "$@"
