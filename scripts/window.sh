#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    tr|tl|halve|qtr|quarter) window "$@";;
    vtr) vtr "$@";;
    window) window "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARGS...

Commands:

    vtr
    window tr|tl|halve|htr|qtr|quarter...
EOF
    return 1
}

vtr() {
    local w ww wh sw sh
    IFS=x read -r sw sh < <(xdpyinfo | awk '/^  dimensions:/{print$2}')
    w=$(xdotool getwindowfocus)
    i3-msg --quiet 'floating enable; border none'
    read -r ww wh < <(
        xdotool getwindowgeometry --shell "$w" \
            | awk -F = 'NR==4||NR==5{printf("%s ",$2)}END{print"\n"}')
    while [[ $ww -gt $((sw / 3)) || $wh -gt $((sh / 3)) ]]; do
        ww=$((ww / 2)); wh=$((wh / 2))
    done
    xdotool \
        windowsize "$w" "$ww" "$wh" \
        windowmove "$w" "$((sw - ww))" 0
}

window() {
    local w ww wh sw sh cmd=
    IFS=x read -r sw sh < <(xdpyinfo | awk '/^  dimensions:/{print$2}')
    read -r w _ _ ww wh _ < <( \
        xdotool selectwindow windowfocus getwindowgeometry --shell \
            | sed 's/^.*=//' \
            | paste -s)
    for x; do
        case "$x" in
        tr) cmd=$(printf '%s\n%s' "$cmd" "windowmove $w $((sw - ww)) 0");;
        tl) cmd=$(printf '%s\n%s' "$cmd" "windowmove $w 0 0");;
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

main "$@"
