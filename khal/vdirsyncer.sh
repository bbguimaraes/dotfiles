#!/bin/bash
set -euo pipefail

p=$(pass show bbguimaraes.com/nextcloud/cal)
cmd='timeout 5m vdirsyncer --verbosity WARNING sync --force-delete'
max=3 n=$max
while { $cmd <<< "$p" && n=$max; } || [[ "$((--n))" -ne 0 ]]; do
    sleep 5m
done
exit 1
