#!/bin/bash
set -euo pipefail

CUR=/sys/class/backlight/intel_backlight/brightness
MAX=/sys/class/backlight/intel_backlight/max_brightness

main() {
    [[ "$#" -eq 0 ]] && { brightness; return; }
    local cmd=$1; shift
    case "$cmd" in
    gui) gui "$@";;
    *) brightness "$cmd" "$@";;
    esac
}

gui() {
    local cur max
    cur=$(<"$CUR")
    max=$(<"$MAX")
    nngn_configure "i:0:$max:$cur:brightness:%1"$'\n' > "$CUR"
}

brightness() {
    local d p
    if [[ "$#" -ne 0 ]]; then
        if ! [[ "$1" =~ [0-9]+% ]]; then
            echo >&2 "invalid percentage: $1"
            return 1
        fi
        p=$1
    else
        d=$(date +%H)
        d=${d#0}
        if [[ "$d" -lt 4 ]]; then p=25
        elif [[ "$d" -lt 14 ]]; then p=50
        elif [[ "$d" -lt 16 ]]; then p=25
        else p=5; fi
    fi
    exec awk -v "p=$p" '{printf "%d", $1 * p / 100.0}' < "$MAX" > "$CUR"
}

main "$@"
