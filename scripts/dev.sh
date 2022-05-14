#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    analog) exec d sink analog-stereo;;
    every) every "$@";;
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

every() {
    local i=$1; shift
    local t d
    t=$EPOCHREALTIME
    while :; do
        "$@"
        d=$(bc -l <<< "$EPOCHREALTIME - $t")
        t=$(bc -l <<< "$t + $i")
        if [[ "$(bc -l <<< "$EPOCHREALTIME < $t")" -eq 1 ]]; then
            sleep "$(bc -l <<< "$t - $EPOCHREALTIME")"
        else
            printf >&2 \
                'warning: execution started %fs after the expected time\n' \
                "$(bc -l <<< "$d - $i")"
        fi
    done
}

main "$@"
