#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    [[ "$#" -eq 1 ]] && { browser "$@"; return; }
    local cmd=$1; shift
    case "$cmd" in
    ddg) ddg "$@";;
    priv) exec firefox --private-window "$@";;
    vim) cmd_vim "$@";;
    wt) wt "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD [ARGS...]

Commands:

    URL
    ddg|wt QUERY...
    vim URL
EOF
    return 1
}

terminal() {
    local cmd=("$@")
    tty --quiet || cmd=("$TERMINAL" -e "${cmd[@]}")
    "${cmd[@]}"
}

browser() {
    terminal lynx -accept_all_cookies -cookie_file /dev/null "$@"
}

ddg() {
    local IFS=+
    browser "https://html.duckduckgo.com/html?q=$*"
}

cmd_vim() {
    local html=$(lynx -display_charset=utf-8 -collapse_br_tags -dump "$1")
    terminal bash -c 'vim - <<< $1' bash "$html"
}

wt() {
    local IFS=+
    browser "https://en.wiktionary.com/wiki/$*"
}

main "$@"
