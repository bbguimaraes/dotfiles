#!/bin/bash
set -euo pipefail

local cmd=(xargs --max-args 1 --max-procs 0 --delimiter $'\n')
while [[ "$#" -ne 0 && "$1" != -- ]]; do
    cmd+=("$1")
    shift
done
[[ "$#" -ne 0 ]] && shift
IFS=$'\n'
"${cmd[@]}" <<< "$*"
