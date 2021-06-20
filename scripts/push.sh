#!/bin/bash
set -euo pipefail

args=()
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
    case "$PWD" in
    */src/es/*) n=comp/es/gitlab;;
    *)
        case "$(git remote get-url "$x")" in
        *github.com/*) n=comp/github/oauth_token;;
        *gitlab.bbguimaraes.com/*) n=bbguimaraes.com/gitlab/bbguimaraes;;
        *git.bbguimaraes.com/*) n=bbguimaraes.com/git;;
        esac
    esac
    [[ "$n" ]]
    git \
        -c "credential.helper=$(printf \
            '!f() { printf password= && pass show %s; } && f' \
            "$n")" \
        push "$x" "${args[@]}"
done
