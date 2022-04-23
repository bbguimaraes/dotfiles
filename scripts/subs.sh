#!/bin/bash
set -euo pipefail

CMDS=(archive archived dailywire play update watched)
VIM=(vim -c 'set buftype=nofile' -c 'set nowrap' -)
VIDEOS=(subs videos --fields yt_id,url,title)

main() {
    local cmd=unwatched
    [[ "$#" -ne 0 ]] && { local cmd=$1; shift; }
    case "$cmd" in
    archive) awk '/^\s/{print$1}' | xargs subs tag archive --;;
    archived) "${VIDEOS[@]}" --tags archive | "${VIM[@]}";;
    complete) cmd_complete;;
    dailywire) "${VIDEOS[@]}" --tags dailywire --unwatched | "${VIM[@]}";;
    enqueue)
        subs videos --unwatched --untagged --flat --fields url \
            | xargs celluloid --enqueue;;
    play)
        case "${1:-}" in
        '') subs videos --unwatched --untagged --flat --fields url \
            | xargs mpv;;
        *) awk '/^\s/ { print $2 }' "$1" | xargs mpv;;
        esac
        ;;
    unwatched) "${VIDEOS[@]}" --unwatched --untagged | "${VIM[@]}";;
    update)
        local args=(--delay 2)
        case "${1:-normal}" in
        normal) args=(--cache "$((60 * 60))");;
        force) args=(--cache 0);;
        fast) args=(
            --cache "$((60 * 60))"
            --last-video "$((7 * 24 * 60 * 60))");;
        esac
        exec subs --verbose update "${args[@]}";;
    watched) awk '/^\s/{print$1}' | xargs subs watched --;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARGS...]

Commands:

    archive
    archived
    complete
    dailywire
    enqueue
    play ARGS...
    unwatched
    update ARGS...
    watched
EOF
    return 1
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
