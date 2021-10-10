#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    cloc) cloc "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

cloc() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    plot) cloc_plot "$@";;
    *) echo >&2 "invalid command: cloc $cmd"; return 1;;
    esac
}

cloc_plot() {
    command cloc --csv --quiet "$@" \
        | head --lines -1 \
        | sort --reverse --numeric --field-separator , --key 5,5 \
        | gnuplot -e '
set term pngcairo size 1600,600;
set datafile separator ",";
set key off;
set xtics rotate nomirror scale 0;
set style fill solid;
set boxwidth 0.75;
plot "-" using 5:xtic(2) with boxes;
'
}

main "$@"
