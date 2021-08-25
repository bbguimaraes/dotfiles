#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    '') pr;;
    status) status "$@";;
    watch) watch "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

pr() {
    local branch helper
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$branch" == master ]]; then
        echo >&2 'refusing to push master'
        exit 1
    fi
    helper='!f() { printf password=; pass show comp/github/oauth_token; }; f'
    pass show test > /dev/null
    git -c "credential.helper=$helper" push --set-upstream github "$branch"
    hub pull-request
}

status() {
    if ! hub ci-status --verbose --color "$@" | cut -f 1-2; then
        [[ "${PIPESTATUS[0]}" -eq 2 ]]
    fi
}

watch() {
    exec watch \
        --beep --color --exec --no-title --interval 60 \
        bash -c 'printf "%s\n\n" "$1"; shift; "$@"' \
        bash "$(printf %q "$*")" "$0" status "$@"
}

main "$@"
