#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    [[ "$#" -eq 1 ]] && { d terminal d web lynx "$@"; return; }
    local cmd=$1; shift
    case "$cmd" in
    ddg) ddg "$@";;
    dmenu) cmd_dmenu "$@";;
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

ddg() {
    local IFS=+
    lynx "https://html.duckduckgo.com/html?q=$*"
}

cmd_dmenu() {
    [[ "$#" -ne 1 ]] && usage
    local cmd=$1 term
    case "$cmd" in
    ddg|wikt) ;;
    *) usage;;
    esac
    term=$(dmenu -p 'term:' <<< '')
    d terminal d web "$cmd" "$term"
}

cmd_vim() {
    local html
    html=$(lynx --dump "$1")
    d terminal bash -c 'vim - <<< $1' bash "$html"
}

wikt() {
    local IFS=+
    lynx "https://en.wiktionary.org/wiki/$*"
}

main "$@"
