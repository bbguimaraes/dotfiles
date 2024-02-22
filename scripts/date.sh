#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && { cmd_date; return; }
    local cmd=$1; shift
    case "$cmd" in
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARGS...]
EOF
    return 1
}

cmd_date() {
    local d='date --rfc-3339=seconds' n tz
    while read n tz; do
        printf '%2s ' "$n"
        TZ=$tz $d
    done <<'EOF'
P US/Pacific
E US/Eastern
BR America/Sao_Paulo
CE Europe/Prague
EOF
}

main "$@"
