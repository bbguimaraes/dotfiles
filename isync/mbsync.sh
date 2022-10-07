#!/bin/bash
set -euo pipefail

p=$(pass show comp/protonmail/bridge)
cmd=(mbsync "$@")
max=3 n=$max
while { "${cmd[@]}" <<< "$p" && n=$max; } || [[ "$((--n))" -ne 0 ]]; do
    sleep 5m
done
exit 1
