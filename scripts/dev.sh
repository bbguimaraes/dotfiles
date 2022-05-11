#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    analog) exec d sink analog-stereo;;
    hdmi) exec d sink hdmi-stereo;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:
EOF
    return 1
}

main "$@"
