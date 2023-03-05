#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    booklet) booklet "$@";;
    codex) exec mupdf ~/src/codex/tex/codex.pdf;;
    ephemeris) exec mupdf ~/src/ephemeris/ephemeris.pdf;;
    historia) exec mupdf ~/src/summa/historiae/historiae.pdf;;
    lingua) exec mupdf ~/src/summa/linguae/linguae.pdf;;
    missale) exec mupdf ~/src/libri/missale/missale.pdf;;
    sanitas) exec mupdf ~/src/summa/sanitatis/sanitatis.pdf;;
    split) split "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: pdf cmd

Commands:

    codex|ephemeris|historiae|linguae|missale|sanitatis
    booklet INPUT N_PAGES
    split images [ARGS...]
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

booklet() {
    local input=$1 n; shift
    n=$(pdfinfo "$input" | awk -F ':\\s*' '$1 == "Pages" { print $2 }')
    # https://github.com/rrthomas/pdfjam-extras.git
    ./pdfbook --signature "$n" "$input" "$@"
}

main "$@"
