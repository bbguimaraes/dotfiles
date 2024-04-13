#!/bin/bash
set -euo pipefail

main() {
    local args=() cred x
    while [[ "$#" -gt 0 ]]; do
        if [[ "$1" == -- ]]; then
            shift
            break
        fi
        args+=("$1")
        shift
    done
    command pass show test > /dev/null
    if [[ "$#" -eq 0 ]]; then
        set $(git remote)
    fi
    for x; do
        cred=$(get_cred "$PWD" "$x")
        push "$x" "$cred" "${args[@]}"
    done
}

get_cred() {
    local dir=$1 repo=$2
    case "$dir" in
    */src/es/*) echo comp/es/gitlab; return;;
    esac
    case "$(git remote get-url "$x")" in
    *github.com/*) echo comp/github/oauth_token; return;;
    *gitlab.bbguimaraes.com/*) echo bbguimaraes.com/gitlab/bbguimaraes; return;;
    *git.bbguimaraes.com/*) echo bbguimaraes.com/git; return;;
    esac
    echo >&2 "unknown repository: $repo"
    return 1
}

push() {
    local target=$1 cred=$2; shift 2
    git \
        -c "credential.helper=$(printf \
            '!f() { printf password= && pass show %s; } && f' \
            "$cred")" \
        push "$target" "$@"
}

main "$@"
