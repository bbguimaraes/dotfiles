#!/bin/bash
set -euo pipefail

CMDS=(archive archived dailywire play update watched)
VIM=(vim -c 'set buftype=nofile' -c 'set nowrap' -)
VIDEOS=(subs videos --fields yt_id,url,title)

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    complete) cmd_complete;;
    play)
        case "${1:-}" in
        '') subs videos --unwatched --untagged --flat --fields url \
            | xargs mpv;;
        *) awk '/^\s/ { print $2 }' "$1" | xargs mpv;;
        esac
        ;;
    enqueue)
        subs videos --unwatched --untagged --flat --fields url \
            | xargs celluloid --enqueue;;
    ''|unwatched) "${VIDEOS[@]}" --unwatched --untagged | "${VIM[@]}";;
    archive) awk '/^\s/{print$1}' | xargs subs tag archive --;;
    archived) "${VIDEOS[@]}" --tags archive | "${VIM[@]}";;
    dailywire) "${VIDEOS[@]}" --tags dailywire --unwatched | "${VIM[@]}";;
    watched) awk '/^\s/{print$1}' | xargs subs watched --;;
    update)
        local args=(--delay 2)
        case "${2:-normal}" in
        normal) args=(--cache "$((60 * 60))");;
        force) args=(--cache 0);;
        fast) args=(
            --cache "$((60 * 60))"
            --last-video "$((7 * 24 * 60 * 60))");;
        esac
        exec subs --verbose update "${args[@]}";;
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

main "$@"
