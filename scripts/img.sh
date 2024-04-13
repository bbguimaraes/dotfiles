#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    date) cmd_date "$@";;
    rename) cmd_rename "$@";;
    resize) cmd_resize "$@";;
    *) usage
    esac
}

usage() {
    cat <<EOF
Usage: $0 CMD ARG...

Commands:

    date FILE...
    rename [-v|--verbose|-n|--dry-run] FILE...
    resize X Y FILE
EOF
    return 1
}

cmd_date() {
    [[ "$#" -eq 0 ]] && usage
    local x date name
    for x; do
        date=$(identify -format '%[date:create]' "$x")
        name=$(date --utc +"%Y%m%d_%H%M%S")
        echo "$name"
    done
}

cmd_rename() {
    local verbose= dry_run=
    while [[ "$#" -ne 0 ]]; do
        case "$1" in
        -v|--verbose) verbose=1; shift;;
        -n|--dry-run) dry_run=1; shift;;
        --) shift; break;;
        -*) usage;;
        *) break;;
        esac
    done
    local x ext dst
    for x; do
        ext=${x##*.}
        if [[ "$x" == "$ext" ]]; then
            echo >&2 "$x: no extension"
            return 1
        fi
        dst=IMG_$(cmd_date "$x").$ext
        [[ "$verbose" ]] && echo "$x" "$dst"
        [[ "$dry_run" ]] || mv --interactive "$x" "$dst"
    done
}

cmd_resize() {
    [[ "$#" -eq 3 ]] || usage
    local x=$1 y=$2 f=$3
    local size=${x}x${y}
    convert \
        -background black \
        -gravity center \
        -resize "$size" \
        -extent "$size" \
        "$f" -
}

main "$@"
