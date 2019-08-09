#!/bin/bash
set -euo pipefail

p=$(pass show nextcloud/cal)
while timeout 5m vdirsyncer --verbosity WARNING sync --force-delete <<< "$p"
do sleep 5m; done
