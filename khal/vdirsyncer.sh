#!/bin/bash
set -euo pipefail

p=$(pass show nextcloud/cal)
while timeout 5m vdirsyncer sync --force-delete <<< "$p"; do
    echo done
    sleep 5m
done
