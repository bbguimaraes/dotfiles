#!/bin/bash
set -euo pipefail

f=$1
dir=$(basename "$f")
dir=$(sed --regexp-extended 's/\.tar(\.\w+)?$//' <<< "$dir")
list=$(tar -tf "$f" | cut -d / -f 1 | sort -u)
[[ "$list" == "$dir" ]] || { echo >&2 "$f" is a bad citizen; exit 1; }
tar -xf "$f"
