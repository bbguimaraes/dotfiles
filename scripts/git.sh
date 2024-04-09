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
    diff) cmd_diff "$@";;
    graph) graph "$@";;
    pull) pull "$@";;
    rebase) rebase "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARGS...

Commands:

    complete
    authors file ARGS...
    authors weekday ARGS...
    backport REV
    diff log [DIFF_ARGS...] REV0 REV1
    graph
    bbguimaraes exec CMD...
    pull
    rebase branches [BRANCHES...]
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

graph() {
    git log --oneline --graph "$@"
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
    base=$(git rev-parse --abbrev-ref HEAD)
    [[ "$#" -eq 0 ]] && set -- $(git branch --no-merged)
    for x; do
        git merge-base --is-ancestor "$base" "$x" && continue
        sleep "$n"; n=1 # for unique timestamps
        git rebase --rebase-merges "$base" "$x"
    done
    git switch "$base"
}

main "$@"
