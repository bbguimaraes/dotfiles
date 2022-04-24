#!/usr/bin/env bash
set -euo pipefail

test -v BUILD_DIR && set -- -C "$BUILD_DIR" "$@"
exec make "$@"
