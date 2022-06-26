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
    diff) cmd_diff "$@";;
    bbguimaraes) bbguimaraes "$@";;
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
    diff log REV0 REV1
    bbguimaraes exec CMD...
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
    *) echo >&2 "invalid command: rebase $cmd"; return 1
    esac
}

diff_log() {
    diff -u <(git log --format=%s "$1" --) <(git log --format=%s "$2" --)
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
