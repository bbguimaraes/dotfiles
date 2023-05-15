#!/bin/bash
set -euo pipefail

SINGLE=eDP-1
HDMI=HDMI-2
DOCK=DP-2-1

main() {
    local cmd=toggle
    [[ "$#" -ne 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    toggle) sleep .1; toggle;;
    *) displays "$cmd" "$@";;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD] ARGS...

Commands:

    toggle
    home|dock single|mirror|dual|tv|120hz|4k
EOF
    return 1
}

displays() {
    local where=$1 mode=$2
    local first=$SINGLE second third
    case "$where" in
    home|dock)
        if [[ "$where" == dock ]]; then second=$DOCK
        elif [[ "$HOSTNAME" == rh* ]]; then second=$HDMI
        else second=HDMI-1; fi
        case "$mode" in
        single)
            xrandr \
                --output "$first" --auto --primary \
                --output "$second" --off;;
        mirror)
            xrandr \
                --output "$first" --auto --primary \
                --output "$second" --auto \
                --mode 1920x1080 -r 60 --same-as "$first";;
        dual)
            xrandr \
                --output "$first" --auto \
                --output "$second" --auto --primary \
                --mode 1920x1080 -r 60 --above "$first"
            workspaces "$first" "$second";;
        tv) xrandr \
            --output "$first" --off \
            --output "$second" --auto --primary --mode 1920x1080 -r 60;;
        120hz) xrandr \
            --output "$first" --off \
            --output "$second" --auto --primary --mode 1920x1080 -r 120;;
        4k) xrandr \
            --output "$first" --off \
            --output "$second" --auto --primary --mode 4096x2160;;
        esac
    esac
}

toggle() {
    local current display out
    out=$(xrandr | awk -v "SINGLE=$SINGLE" '
/^\S/ { section = $1 }
/\*/ { current  = section }
section != SINGLE && $2 == "connected" { display = section }
END { print current, display }')
    read -r current display <<< "$out"
    case "$current" in
    $SINGLE)
        case "$display" in
        $DOCK) displays dock dual;;
        $HDMI) displays home dual;;
        esac;;
    $DOCK) displays dock single;;
    $HDMI) displays home single;;
    esac
    return
}

workspaces() {
    local first=$1 second=$2
    i3-msg workspace 1
    i3-msg move workspace to output "$second"
    i3-msg workspace 2
    i3-msg move workspace to output "$second"
    i3-msg workspace 3
    i3-msg move workspace to output "$first"
    i3-msg workspace 4
    i3-msg move workspace to output "$second"
    i3-msg workspace 4
    i3-msg workspace 1
}

main "$@"
