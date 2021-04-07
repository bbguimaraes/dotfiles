#!/bin/bash
set -euo pipefail

perf record -g -- "$@"
perf script \
    | stackcollapse-perf.pl \
    | flamegraph.pl > flamegraph.svg
