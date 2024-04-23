#!/bin/bash
set -euo pipefail

SESSION=0

main() {
    local SESSION=0 target
    if tmux has-session -t "$SESSION" &> /dev/null; then
        attach
    fi
    local target=$SESSION
    tmux new-session -s "$SESSION" -d
    tmux rename-window -t "$target" ''
    tmux respawn-pane -t "$target:0" -k d todo
    tmux split-window -t "$target:0.0" -l 1000 top -o %CPU
    tmux split-window -t "$target:0.1" -l 1000 journalctl -f
    tmux split-window -t "$target:0.2" -l 1000 custos --clear
    tmux select-layout -t "$target:0" main-vertical
    tmux new-window -t "$target:1" weechat
    tmux split-window -t "$target:1.0" -l 1000 d mutt
    tmux split-window -t "$target:1.1" -l 1000 newsboat
    tmux split-window -t "$target:1.2" -l 1000 ikhal
    tmux select-layout -t "$target:1" main-horizontal
    attach
}

attach() { exec tmux attach -t "$SESSION"; }

main "$@"
