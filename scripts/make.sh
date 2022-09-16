#!/usr/bin/env bash
set -euo pipefail

bin=$0
bin=$(basename "$0")
bin=${bin%.*}

test -v BUILD_DIR && set -- -C "$BUILD_DIR" "$@"
case "$(basename "$0")" in
make-pdf)
    make "$@"
    pkill -HUP mupdf;;
*)
    exec make "$@";;
esac
