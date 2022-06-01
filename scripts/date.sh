#!/bin/bash
set -euo pipefail

d='date --rfc-3339=seconds'
while read n tz; do
    printf '%2s ' "$n"
    TZ=$tz $d
done <<'EOF'

P US/Pacific
E US/Eastern
BR America/Sao_Paulo
CE Europe/Prague
EOF
