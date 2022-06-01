#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    java) common \
        base jdk8-openjdk make libxrender libxtst ttf-dejavu xorg-server;;
    latex) common \
        base inotify-tools make texlive-core texlive-bin texlive-langgreek \
        texlive-latexextra;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARGS...

Commands:

    java|latex
EOF
    return 1
}

common() {
    pacstrap -cd "$1" -u --needed "$@"
}

main "$@"
