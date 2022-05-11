#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && { pr; return; }
    local cmd=$1; shift
    case "$cmd" in
    comment) comment "$@";;
    for-ref) for_ref "$@";;
    status) status "$@";;
    watch) watch "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARGS...]

Commands:

    for-ref REFS...
    status HUB_ARGS...
    watch HUB_ARGS...
EOF
    return 1
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

comment() {
    [[ "$#" -eq 0 ]] && { echo >&2 missing argument: body; return 1; }
    local body=$1 n
    n=$(hub pr show --format %I)
    hub api \
        "repos/{owner}/{repo}/issues/$n/comments" \
        --method POST --raw-field "body=$1"
}

for_ref() {
    [[ "$#" -eq 0 ]] && set -- HEAD
    local x j
    for x; do
        x=$(git rev-parse "$x")
        j=$(hub api "search/issues?q=org:{owner}+repo:{repo}+sha:$x")
        if [[ "$(jq <<< "$j" .total_count)" -eq 0 ]]; then
            echo "$x"
        else
            printf '%s ' "$x"
            jq --raw-output <<< "$j" '[.items[].html_url]|join(" ")'
        fi
    done
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
