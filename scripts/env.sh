#!/bin/bash
set -euo pipefail

SESSION=0

main() {
    local SESSION=0 target
    if tmux has-session -t "$SESSION" &> /dev/null; then
        attach
    fi
    local target=$SESSION:0
    local mutt
    case "$HOSTNAME" in
    rh*) mutt=redhat;;
    *) mutt=proton;;
    esac
    tmux new-session -s "$SESSION" -d
    tmux rename-window -t "$target" ''
    tmux respawn-pane -t "$target" -k top -o %CPU
    tmux split-window -t "$target.0" -l 1000 journalctl -f
    tmux split-window -t "$target.1" -l 1000 ikhal
    tmux split-window -t "$target.2" -l 1000 d todo
    tmux split-window -t "$target.3" -l 1000 d mutt "$mutt"
    tmux split-window -t "$target.4" -l 1000 newsboat
    tmux split-window -t "$target.5" -l 1000 d custos
    tmux split-window -t "$target.6" -l 1000
    case "$HOSTNAME" in
    rh*)
        tmux select-layout -t "$target" tiled
        tmux new-window -t "$SESSION:1" weechat
        tmux split-window -t "$SESSION:1.0" -l 1000 rh irssi
        tmux select-layout -t "$target" even-vertical;;
    *)
        tmux split-window -t "$target.7" -l 1000 d weechat
        tmux select-layout -t "$target" tiled;;
    esac
    attach
}

attach() { exec tmux attach -t "$SESSION"; }

main "$@"
