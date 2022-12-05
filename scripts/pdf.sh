#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    split) split "$@";;
    two-per-sheet) two_per_sheet "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: pdf cmd

Commands:

    split images [ARGS...]
    two-per-sheet INPUT OUTPUT N_PAGES
EOF
    return 1
}

split() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    images) split_images "$@";;
    *) usage;;
    esac
}

split_images() {
    exec convert -verbose -density 150 -quality 100 -sharpen 0x1.0 "$@"
}

two_per_sheet() {
    local input=$1 n_pages=$2 h p0 p1 pages
    h=$(((n_pages + 1) / 2))
    p0=$(seq 1 "$h")
    p1=$(seq "$((h + 1))" "$n_pages"; ((n_pages % 2)) && echo '{}')
    pages=$( \
        paste - <<< $p0 <(tac <<< $p1) \
            | awk -v OFS=, 'NR%2{print($1,$2);next}{print($2,$1)}' \
            | paste --serial --delimiter ,)
    pdfjam --reflect true "$input" "$pages" -o /dev/stdout \
        | pdfjam --landscape --nup 2x1 -o /dev/stdout \
        | pdfjam --suffix nup --reflect true --fitpaper true -o /dev/stdout
}

main "$@"
