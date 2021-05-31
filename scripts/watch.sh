#!/bin/bash
set -euo pipefail

VIM_FILE=4913

inotifywait \
        --quiet --monitor --recursive \
        --event close_write --format %f . \
    | grep --line-buffered --line-regexp --invert-match "$VIM_FILE"
