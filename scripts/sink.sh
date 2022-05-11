#!/bin/bash
set -euo pipefail

sinks=$(pactl list short sinks)
[[ "$#" -eq 0 ]] && { echo "$sinks"; exit; }
sink=$1
if ! [[ "$sink" =~ [0-9]+ ]]; then
    id=$(awk -v s="$sink" '$2 ~ s { print $1; exit }' <<< "$sinks")
fi
if [[ "$id" ]]; then
    pactl set-default-sink "$id"
    pactl list short sink-inputs | while read -r stream _; do
        pactl move-sink-input "$stream" "$id"
    done
fi
if [[ "$HOSTNAME" == wamozart ]]; then
    card=; profile=
    case "$sink" in
    hdmi-stereo)
        card=$(pactl list short cards | awk '{print $1; exit}')
        profile=output:hdmi-stereo-extra1+input:analog-stereo;;
    analog-stereo)
        card=$(pactl list short cards | awk '{print $1; exit}')
        profile=output:analog-stereo+input:analog-stereo;;
    esac
    [[ "$card" && "$profile" ]] \
        && pactl set-card-profile "$card" "$profile"
fi
