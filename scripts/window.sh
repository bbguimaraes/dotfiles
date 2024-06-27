#!/bin/bash
set -euo pipefail

BORDER=1
PAD=16

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    tr|tl|double|halve|qtr|quarter) window "$cmd" "$@";;
    vtr) vtr "$@";;
    window) window "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    vtr [-s]
    window [-s] tr|tl|double|halve|htr|qtr|quarter...
EOF
    return 1
}

right() {
    local sw=$1 ww=$2
    echo "$((sw - ww - PAD - BORDER))"
}

top() {
    echo "$((2 * PAD + 3 * BORDER))"
}

vtr() {
    [[ "$#" -gt 1 ]] && usage
    local w ww wh sw sh
    IFS=x read -r sw sh < <(xdpyinfo | awk '/^  dimensions:/{print$2}')
    w=$(select_window "$@")
    i3-msg --quiet 'floating enable; sticky enable; border pixel'
    read -r ww wh < <(
        xdotool getwindowgeometry --shell "$w" \
            | awk -F = 'NR==4||NR==5{printf("%s ",$2)}END{print"\n"}')
    while [[ $ww -gt $((sw / 2)) || $wh -gt $((sh / 2)) ]]; do
        ww=$((ww / 2)); wh=$((wh / 2))
    done
    xdotool \
        windowsize "$w" "$ww" "$wh" \
        windowmove "$w" "$(right "$sw" "$ww")" "$(top)"
}

window() {
    local w ww wh sw sh cmd=
    w=$(select_window "$@")
    IFS=x read -r sw sh < <(xdpyinfo | awk '/^  dimensions:/{print$2}')
    read -r w _ _ ww wh _ < <( \
        xdotool windowfocus "$w" getwindowgeometry --shell "$w" \
            | sed 's/^.*=//' \
            | paste -s)
    for x; do
        case "$x" in
        tr) cmd=$(printf '%s\n%s' "$cmd" "windowmove $w $((sw - ww)) 0");;
        tl) cmd=$(printf '%s\n%s' "$cmd" "windowmove $w 0 0");;
        double)
            ww=$((ww * 2)); wh=$((wh * 2))
            cmd=$(printf '%s\n%s' "$cmd" "windowsize $w $ww $wh") ;;
        halve)
            ww=$((ww / 2)); wh=$((wh / 2))
            cmd=$(printf '%s\n%s' "$cmd" "windowsize $w $ww $wh") ;;
        htr)
            ww=$((ww / 2)); wh=$((wh / 2))
            cmd=$(printf '%s\n%s' "$cmd" "windowsize $w $ww $wh")
            cmd=$(printf '%s\n%s' "$cmd" "windowmove $w $((sw - ww)) 0");;
        qtr)
            ww=$((ww / 4)); wh=$((wh / 4))
            cmd=$(printf '%s\n%s' "$cmd" "windowsize $w $ww $wh")
            cmd=$(printf '%s\n%s' "$cmd" "windowmove $w $((sw - ww)) 0");;
        quarter)
            ww=$((ww / 4)); wh=$((wh / 4))
            cmd=$(printf '%s\n%s' "$cmd" "windowsize $w $ww $wh") ;;
        *) usage;;
        esac
    done
    xdotool - <<< "$cmd"
}

select_window() {
    if [[ "$#" -gt 0 && "$1" == -s ]]; then
        xdotool selectwindow
    else
        xdotool getwindowfocus
    fi
}

main "$@"
