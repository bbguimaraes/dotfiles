#!/bin/bash
set -euo pipefail

exec markdown -f fencedcode,footnote,links "$@"
