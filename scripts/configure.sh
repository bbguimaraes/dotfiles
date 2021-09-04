#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    dir) dir "$@";;
    clean) clean "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

dir() {
    local d0=$PWD d1=$1; shift
    [[ -e "$d1" ]] || mkdir "$d1"
    cd "$d1"
    "$d0/configure" "$@"
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
