#!/bin/bash
set -euo pipefail

SESSION_MAIN=0
SESSION_SCRATCH=1
SESSION_WORK=dds

main() {
    session_main
    session_scratch
    session_work
    exec tmux attach -t "$SESSION_MAIN"
}

session_main() {
    local target=$SESSION_MAIN
    has_session "$target" && return
    new_session "$target"
    rename_window "$target" ''
    respawn_pane "$target:0" d todo
    split_window "$target:0.0" top -o %CPU
    split_window "$target:0.1" journalctl -f
    split_window "$target:0.2" custos --clear
    select_layout "$target:0" main-vertical
    new_window "$target:1" weechat
    rename_window "$target:1" ''
    split_window "$target:1.0" d mutt
    split_window "$target:1.1" newsboat
    split_window "$target:1.2" ikhal
    select_layout "$target:1" main-horizontal
    new_window "$target:2" subs tui
    rename_window "$target:2" v
}

session_scratch() {
    local target=$SESSION_SCRATCH
    has_session "$target" && return
    new_session "$target"
    rename_window "$target" ''
    respawn_pane "$target:0" vim
    split_window "$target:0.0"
    select_layout "$target:0" even-vertical
}

session_work() {
    local target=$SESSION_WORK
    has_session "$target" && return
    new_session "$target" -d
    rename_window "$target" ''
    respawn_pane "$target:0" -c dds/ vim n/dds.md
    split_window "$target:0.0" d mutt dds
    select_layout "$target:0" main-vertical
}

has_session() {
    tmux has-session -t "$1" &> /dev/null
}

new_session() {
    tmux new-session -s "$1" -d
}

rename_window() {
    tmux rename-window -t "$1" "$2"
}

respawn_pane() {
    local target=$1; shift
    tmux respawn-pane -t "$target" -k $@
}

split_window() {
    local target=$1; shift
    tmux split-window -t "$target" -l 1000 $@
}

new_window() {
    local target=$1; shift
    tmux new-window -t "$target" "$@"
}

rename_window() {
    tmux rename-window -t "$1" "$2"
}

select_layout() {
    tmux select-layout -t "$1" "$2"
}

main "$@"
