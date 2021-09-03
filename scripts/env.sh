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
    if [[ "$HOSTNAME" != wamozart ]]; then
        tmux split-window -t "$target.3" -l 1000 d mutt proton
        tmux split-window -t "$target.4" -l 1000 d mutt gmail
        tmux split-window -t "$target.5" -l 1000 d weechat
        tmux split-window -t "$target.6" -l 1000
        tmux select-layout -t "$target" tiled
    else
        tmux split-window -t "$target.3" -l 1000 d mutt redhat
        tmux split-window -t "$target.4" -l 1000 \
            ssh -t file.emea.redhat.com screen -dR
        tmux select-layout -t "$target" tiled
        tmux new-window -t "$SESSION:1" d weechat
    fi
    attach
}

attach() { exec tmux attach -t "$SESSION"; }

main "$@"
