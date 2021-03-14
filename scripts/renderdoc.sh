#!/bin/bash
set -euo pipefail

tmp=$(mktemp --tmpdir renderdoc.XXXXXXXXXX)
trap 'rm "$tmp"*' EXIT
renderdoccmd capture \
    --wait-for-exit \
    --capture-file "$tmp" \
    --working-dir "$PWD" \
    "$@"
qrenderdoc "$tmp"_frame*.rdc
