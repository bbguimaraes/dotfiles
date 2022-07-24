#!/bin/bash
set -euo pipefail

PATH=$PATH:$HOME/src/FlameGraph
perf record -g -- "$@"
perf script \
    | stackcollapse-perf.pl \
    | flamegraph.pl > flamegraph.svg
