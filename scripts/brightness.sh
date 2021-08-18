#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    gui) gui "$@";;
    *) brightness "$@";;
    esac
}

gui() {
    local cur_f=/sys/class/backlight/intel_backlight/brightness
    local max_f=/sys/class/backlight/intel_backlight/max_brightness
    local cur max
    cur=$(<"$cur_f")
    max=$(<"$max_f")
    nngn_configure "i:0:$max:$cur:%1"$'\n' \
        > /sys/class/backlight/intel_backlight/brightness
}

brightness() {
    local d p
    d=$(date +%H)
    d=${d#0}
    if [[ "$d" -lt 4 ]]; then p=25
    elif [[ "$d" -lt 14 ]]; then p=50
    elif [[ "$d" -lt 16 ]]; then p=25
    else p=5; fi
    exec sudo brightness "$p%"
}

main "$@"
