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
    wt) wt "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD [ARG...]

Commands:

    URL
    ddg|wt QUERY...
    lynx [ARG...]
    vim URL
EOF
    return 1
}

lynx() {
    command lynx \
        --display-charset utf-8 \
        --collapse-br-tags \
        --accept-all-cookies \
        --cookie-file /dev/null \
        "$@"
}

terminal() {
    local cmd=("$@")
    tty --quiet || cmd=("$TERMINAL" -e "${cmd[@]}")
    "${cmd[@]}"
}

ddg() {
    local IFS=+
    browser "https://html.duckduckgo.com/html?q=$*"
}

cmd_vim() {
    local html
    html=$(lynx --dump "$1")
    terminal bash -c 'vim - <<< $1' bash "$html"
}

wt() {
    local IFS=+
    browser "https://en.wiktionary.com/wiki/$*"
}

main "$@"
