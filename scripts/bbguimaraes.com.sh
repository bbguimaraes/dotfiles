#!/bin/bash
set -euo pipefail

CMDS=(complete files push-img local sync-docs)

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    complete) cmd_complete;;
    files) files "$@";;
    push-img) push_img "$@";;
    local) _local "$@";;
    sync-docs) sync_docs "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

cmd_complete() {
    local line=($COMP_LINE)
    local n=${#line[@]}
    case "$n" in
    1) compgen -W "${CMDS[*]}";;
    2) compgen -W "${CMDS[*]}" "${line[$((n - 1))]}";;
    esac
}

files() {
#        --rsync-path 'sudo rsync' \
    local host=bbguimaraes.com
    local src=$HOME/src/bbguimaraes.com/bbguimaraes.com/files
    local dst=/mnt/bbguimaraes0-vol/bbguimaraes.com/bbguimaraes.com/
    exec rsync \
        --archive --chown 0:0 \
        "$src" "$host:$dst" "$@"
}

push_img() {
    local name=$1
    sudo podman save "$name" \
        | pixz \
        | ssh bbguimaraes.com 'xzcat | sudo docker load'
}

_local() {
    cd ~/src/bbguimaraes.com/bbguimaraes.com
    exec python -m http.server
}

sync_docs() {
    local out=$HOME/src/bbguimaraes.com/bbguimaraes.com/files
    rsync --archive ~/src/nngn/docs/html/ "$out/nngn/docs"
}

main "$@"
