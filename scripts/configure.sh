#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    clean)
        rm -f \
            Makefile.in aclocal.m4 autoscan.log compile config.h.in \
            config.h.in~ configure configure.scan depcomp install-sh missing \
            test-driver
        rm -rf autom4te.cache/;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

main "$@"
