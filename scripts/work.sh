#!/bin/bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
    echo >&2 "Usage: $0 dir"
    exit 1
fi
name=$1
dir=$name
[[ -e "$dir" ]] || dir=$HOME/src/$name
cd "$dir"
tmux rename-window "$name"
tmux split-window -c "$dir" 'git branch; git status; exec bash -i'
tmux select-layout main-vertical
sleep 1
exec vim
