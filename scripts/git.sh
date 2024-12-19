#!/bin/bash
set -euo pipefail

CMDS=(complete authors backport bbguimaraes diff rebase)

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    complete) cmd_complete "$@";;
    authors) authors "$@";;
    backport) backport "$@";;
    bbguimaraes) bbguimaraes "$@";;
    branch) branch "$@";;
    diff) cmd_diff "$@";;
    github) github "$@";;
    graph) graph "$@";;
    pull) pull "$@";;
    rebase) rebase "$@";;
    upstream) upstream "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    complete
    authors file ARG...
    authors weekday ARG...
    backport REV
    branch
    branch split NAME BASE REV
    diff log [DIFF_ARG...] REV0 REV1
    github pr branch ID
    graph
    graph branch-diff B0 B1
    bbguimaraes exec CMD...
    pull
    rebase branches [BRANCH...]
    upstream
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

authors() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    file) authors_file "$@";;
    weekday) authors_weekday "$@";;
    *) usage;;
    esac
}

authors_file() {
    git blame --porcelain "$@" \
        | awk '$1 ~ /^author(-mail)?$/ { sub("^\\S+ ", ""); print; }' \
        | awk 'NR % 2 { printf("%s ", $0); next } 1' \
        | sort -u
}

authors_weekday() {
    local out
    out=$( \
        git log --format=%ad --date=format-local:'%a %u' "$@" \
        | sort | uniq -c | sort -nk 3,3)
    printf '%s\ne\n%s\n' "$out" "$out" | gnuplot -e "$(cat <<'EOF'
set term dumb;
set key off;
set label;
set boxwidth 0.5 relative;
set offsets 0.5, 0.5;
set yrange [0:];
plot
    "-" using 0:1:xtic(2) with boxes,
    "" using 0:1:1 with labels center offset 0, 1 notitle;
EOF
)"
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

bbguimaraes() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    exec) bbguimaraes_exec "$@";;
    *) usage;;
    esac
}

bbguimaraes_exec() {
    local d
    cd ~/src/bbguimaraes/
    for d in *; do
        printf '\n%s\n\n' "$d"
        pushd "$d/" > /dev/null
        "$@"
        popd > /dev/null
    done
}

branch() {
    [[ "$#" -eq 0 ]] && { git rev-parse --abbrev-ref HEAD && return; }
    local cmd=$1; shift
    case "$cmd" in
    split) branch_split "$@";;
    *) usage;;
    esac
}

branch_split() {
    [[ "$#" -eq 3 ]] || usage
    local name=$1
    local base=$2
    local rev=$3
    base=$(git rev-parse "$base")
    rev=$(git rev-parse "$rev")
    git branch "$name"
    git reset --hard "$rev"
    git rebase --onto "$base" "$rev" "$name"
}

cmd_diff() {
    local cmd
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    log) diff_log "$@";;
    *) usage;;
    esac
}

diff_log() {
    [[ "$#" -lt 2 ]] && usage
    local args=("${@:1}")
    local n=${#args[@]}
    diff \
        "${args[@]:0:$n - 2}" \
        <(git log --format=%s "${args[$n - 2]}" --) \
        <(git log --format=%s "${args[$n - 1]}" --)
}

github() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    pr) github_pr "$@";;
    *) usage;;
    esac
}

github_pr() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    branch) github_pr_branch "$@";;
    *) usage;;
    esac
}

github_pr_branch() {
    [[ "$#" -eq 1 ]] || usage
    git fetch origin "refs/pull/$1/head"
    git switch FETCH_HEAD --create "pull_$1"
}

graph() {
    if [[ "$#" -gt 0 ]]; then
        local cmd=$1; shift
        case "$cmd" in
        branch-diff) graph_branch_diff "$@"; return;;
        esac
    fi
    git log --oneline --graph "$@"
}

graph_branch_diff() {
    [[ "$#" -eq 2 ]] || usage
    local b0=$1 b1=$2 m
    m=$(git merge-base "$b0" "$b1")
    exec git log --oneline --graph "$b0" "$b1" ^"$m"^
}

pull() {
    git branch
    git switch master
    git pull --all --prune "$@"
}

rebase() {
    local cmd
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    branches) rebase_branches "$@";;
    *) usage;;
    esac
}

rebase_branches() {
    local base rev x n=0
    base=$(branch)
    [[ "$#" -eq 0 ]] && set -- $(git branch --no-merged)
    for x; do
        git merge-base --is-ancestor "$base" "$x" && continue
        sleep "$n"; n=1 # for unique timestamps
        git rebase --rebase-merges "$base" "$x"
    done
    git switch "$base"
}

upstream() {
    local b
    if ! b=$(branch); then
        echo >&2 failed to determine current branch
        return 1
    fi
    git config "branch.$b.merge"
}

main "$@"
