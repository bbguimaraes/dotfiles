#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && { pr; return; }
    local cmd=$1; shift
    case "$cmd" in
    comment) comment "$@";;
    for-file) for_file "$@";;
    for-ref) for_ref "$@";;
    status) status "$@";;
    watch) watch "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARG...]

Commands:

    for-file PATH...
    for-ref REF...
    status HUB_ARG...
    watch HUB_ARG...
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

for_file() {
    local open=
    [[ "$#" -ne 0 ]] && [[ "$1" == -o ]] && { open=1; shift; }
    [[ "$#" -eq 0 ]] && usage
    local f r
    for f; do
        r=$(git log --format=%h --max-count 1 -- "$f")
        [[ "$r" ]] && for_ref ${open:+-o} "$r"
    done
}

for_ref() {
    local open= rev url j
    [[ "$#" -ne 0 ]] && [[ "$1" == -o ]] && { open=1; shift; }
    [[ "$#" -eq 0 ]] && set -- HEAD
    for rev; do
        rev=$(git rev-parse "$rev")
        j=$(hub api "search/issues?q=org:{owner}+repo:{repo}+sha:$rev")
        if [[ "$(jq <<< "$j" .total_count)" -eq 0 ]]; then
            echo "$rev"
        else
            printf %s "$rev"
            for url in $( \
                jq --raw-output <<< "$j" '[.items[].html_url]|join(" ")' \
            ); do
                [[ "$open" ]] && xdg-open "$url"
                printf '%s ' " $url"
            done
            echo
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
