#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && { cmd_date; return; }
    local cmd=$1; shift
    case "$cmd" in
    diff) cmd_diff "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARGS...]

Commands:

    diff T0 T1
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

cmd_diff() {
    [[ "$#" -eq 2 ]] || usage
    local t0=$2 t1=$1
    python -c "$(cat <<'EOF'
import datetime
import sys

_, t0, t1 = sys.argv
d = datetime.datetime
f = '%Y-%m-%d'
print(d.strptime(t1, f) - d.strptime(t0, f))
EOF
)" "$t0" "$t1"
}

main "$@"
