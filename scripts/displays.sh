#!/bin/bash
set -euo pipefail

SINGLE=eDP-1
HDMI1=HDMI-1
HDMI2=HDMI-2
DOCK=DP-2-1
OFFICE=DP-2-8

main() {
    local cmd=toggle
    [[ "$#" -ne 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    list) list "$@";;
    toggle) sleep .1; toggle;;
    *) displays "$cmd" "$@";;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD] ARGS...

Commands:

    list
    toggle
    home|dock|office single|mirror|dual|tv|120hz|4k
EOF
    return 1
}

displays() {
    local where=$1 mode=$2 first=$SINGLE second third
    case "$where" in
    dock) second=$DOCK;;
    office) second=$OFFICE;;
    home)
        case "$HOSTNAME" in
        rh*) second=$HDMI1;;
        *) second=$HDMI2;;
        esac;;
    dock|home|office) ;;
    *) usage;;
    esac
    case "$mode" in
    single) displays_single "$first" "$second";;
    dual) displays_dual "$first" "$second";;
    mirror)
        xrandr \
            --output "$first" --auto --primary \
            --output "$second" --auto \
            --mode 1920x1080 -r 60 --same-as "$first";;
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
}

displays_single() {
    xrandr \
        --output "$1" --auto --primary \
        --output "$2" --off
}

displays_dual() {
    xrandr \
        --output "$1" --auto \
        --output "$2" --auto --primary \
        --mode 1920x1080 -r 60 --above "$1"
    workspaces "$1" "$2"
}

list() {
    local out primary
    out=$(xrandr --query)
    primary=$(awk <<< $out '$3 == "primary" { print $1 }')
    echo "$primary"
    awk <<< $out -v "p=$primary" '$2 == "connected" && $1 != p { print $1 }'
}

toggle() {
    local out test primary secondary cmd arg
    out=$(list | paste -s)
    read -r primary secondary <<< $out
    case "$primary" in
    $SINGLE) displays_dual "$primary" "$secondary";;
    *) displays_single "$secondary" "$primary";;
    esac
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
