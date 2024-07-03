#!/bin/bash
set -euo pipefail

BORDER=1
PAD=16

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    corner) corner "$@";;
    bl|br|tl|tr|double|halve|qtr|quarter) window "$cmd" "$@";;
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

bottom() {
    local sh=$1 wh=$2
    echo "$((sh - wh - 19 - PAD))"
}

vtr() {
    [[ "$#" -gt 1 ]] && usage
    local w ww wh sw sh
    IFS=x read -r sw sh < <(xdpyinfo | awk '/^  dimensions:/{print$2}')
    w=$(select_window "$@")
    i3-msg --quiet 'floating enable; sticky toggle; border pixel'
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
        bl) cmd=$(printf '%s\nwindowmove %d %d %d' \
            "$cmd" "$w" \
            "$PAD" \
            "$(bottom "$sh" "$wh")" \
        );;
        br) cmd=$(printf '%s\nwindowmove %d %d %d' \
            "$cmd" "$w" \
            "$(right "$sw" "$ww")" \
            "$(bottom "$sh" "$wh")" \
        );;
        tr) cmd=$(printf '%s\nwindowmove %d %d %d' \
            "$cmd" "$w" \
            "$(right "$sw" "$ww")" \
            "$(top)" \
        );;
        tl) cmd=$(printf '%s\nwindowmove %d %d %d' \
            "$cmd" "$w" "$PAD" "$(top)" \
        );;
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

corner() {
    local w sw sh x y ww wh l r b t
    IFS=x read -r sw sh < <(xdpyinfo | awk '/^  dimensions:/{print$2}')
    w=$(select_window "$@")
    read -r w l t ww wh _ < <( \
        xdotool windowfocus "$w" getwindowgeometry --shell "$w" \
            | sed 's/^.*=//' \
            | paste -s)
    r=$((sw - l - ww))
    b=$((sh - t - wh))
    if [[ "$l" -lt "$r" ]]; then
        if [[ "$t" -lt "$b" ]]; then
            d window tr
        else
            d window tl
        fi
    else
        if [[ "$t" -lt "$b" ]]; then
            d window br
        else
            d window bl
        fi
    fi
}

select_window() {
    if [[ "$#" -gt 0 && "$1" == -s ]]; then
        xdotool selectwindow
    else
        xdotool getwindowfocus
    fi
}

main "$@"
