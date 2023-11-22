#!/bin/bash
set -euo pipefail

SESSION=0

main() {
    local SESSION=0 target
    if tmux has-session -t "$SESSION" &> /dev/null; then
        attach
    fi
    local target=$SESSION:0
    tmux new-session -s "$SESSION" -d
    tmux rename-window -t "$target" ''
    tmux respawn-pane -t "$target" -k top -o %CPU
    tmux split-window -t "$target.0" -l 1000 journalctl -f
    tmux split-window -t "$target.1" -l 1000 ikhal
    tmux split-window -t "$target.2" -l 1000 d todo
    tmux split-window -t "$target.3" -l 1000 d mutt
    tmux split-window -t "$target.4" -l 1000 newsboat
    tmux split-window -t "$target.5" -l 1000 d custos
    tmux split-window -t "$target.6" -l 1000 weechat
    tmux select-layout -t "$target" tiled
    attach
}

attach() { exec tmux attach -t "$SESSION"; }

main "$@"
