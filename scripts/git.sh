#!/bin/bash
set -euo pipefail

CMDS=(complete authors backport rebase)

main() {
    local cmd
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    complete) cmd_complete "$@";;
    authors) authors "$@";;
    backport) backport "$@";;
    rebase) rebase "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1
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

authors() {
    git blame --porcelain "$@" \
        | awk '$1 ~ /^author(-mail)?$/ { sub("^\\S+ ", ""); print; }' \
        | awk 'NR % 2 { printf("%s ", $0); next } 1' \
        | sort -u
}

backport() {
    local rev=$1 cur base
    rev=$(git rev-parse "$rev")
    cur=$(git rev-parse HEAD)
    base=$(git merge-base "$cur" "$rev")
    if [[ "$base" != "$rev" ]]; then
        echo >&2 'invalid ancestor'
        return 1
    fi
    git stash push
    git reset --hard "$rev"
    git stash pop
    git add -u
    git commit --amend --no-edit
    git cherry-pick "$rev..$cur"
}

rebase() {
    local cmd
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    branches) rebase_branches "$@";;
    *) echo >&2 "invalid command: rebase $cmd"; return 1
    esac
}

rebase_branches() {
    local x
    git switch master
    [[ "$#" -eq 0 ]] && set -- $(git branch --no-merged)
    git rebase master "$1"
    shift
    for x; do
        sleep 1 # for unique timestamps
        git rebase master "$x"
    done
}

main "$@"
