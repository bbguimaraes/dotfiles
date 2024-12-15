#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    booklet) booklet "$@";;
    join) join "$@";;
    split) split "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: pdf CMD [ARG...]

Commands:

    booklet INPUT N_PAGES
    join OUTPUT INPUT...
    split images [ARG...]
    split pages INPUT FIRST LAST
EOF
    return 1
}

join() {
    [[ "$#" -lt 2 ]] && usage
    local f=$1; shift
    gs \
        -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite \
        -sOutputFile="$f" "$@"
}

split() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    images) split_images "$@";;
    pages) split_pages "$@";;
    *) usage;;
    esac
}

split_images() {
    exec convert -verbose -density 150 -quality 100 -sharpen 0x1.0 "$@"
}

split_pages() {
    [[ "$#" -eq 3 ]] || usage
    local f=$1 first=$2 last=$3 base ext
    base=${f%.*}
    ext=${f##*.}
    gs \
        -sDEVICE=pdfwrite -dSAFER \
        "-dFirstPage=$first" "-dLastPage=$last" \
        -o "${base}_%d.$ext" "$f"
}

booklet() {
    local input=$1 n; shift
    n=$(pdfinfo "$input" | awk -F ':\\s*' '$1 == "Pages" { print $2 }')
    # https://github.com/rrthomas/pdfjam-extras.git
    ./pdfbook --signature "$n" "$input" "$@"
}

main "$@"
