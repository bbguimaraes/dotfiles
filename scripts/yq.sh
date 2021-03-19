#!/bin/bash
set -euo pipefail

d ytoj | jq "$@" | d jtoy
