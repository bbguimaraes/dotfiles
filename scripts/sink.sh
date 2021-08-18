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
if [[ "$HOSTNAME" == wamozart && "$sink" == hdmi-stereo ]]; then
    card=$(pactl list short cards | awk '{print $1; exit}')
    pactl set-card-profile \
        "$card" output:hdmi-stereo-extra1+input:analog-stereo
fi
