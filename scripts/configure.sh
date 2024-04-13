#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    dir) dir "$@";;
    clean) clean "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    dir DIR CONFIGURE_ARG...
    clean
EOF
    return 1
}

dir() {
    local d0=$PWD d1=$1; shift
    local args=()
    d0=${d0%%/}
    case "${d0##*/}" in
    codex) args=(--enable-benchmarks --enable-tests);;
    esac
    [[ -e "$d1" ]] || mkdir "$d1"
    cd "$d1"
    "$d0/configure" "${args[@]}" "$@"
}

clean() {
    rm -f \
        Makefile.in aclocal.m4 autoscan.log compile config.h.in \
        config.h.in~ config.log configure configure~ configure.scan depcomp \
        install-sh missing test-driver
    rm -rf autom4te.cache/
    find -name Makefile.in -delete
}

main "$@"
