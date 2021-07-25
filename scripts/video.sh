#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    audio) youtube-dl \
        --extract-audio --audio-format vorbis \
        -o '%(title)s.%(ext)s' "$@";;
    split) ~/n/comp/scripts/split_video.py "$@";;
    compress) compress "$@";;
    playlist) playlist "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

compress() {
    local in=$1; shift
    exec ffmpeg \
        -threads "$(nproc)" -i "$in" \
        -acodec copy -quality realtime -speed 0 -crf 33 "$@"
}

playlist() {
    local name=$1 url=$2
    if ! [[ -f "$name.json" ]]; then
        youtube-dl --dump-single-json "$url" > "$name.json"
    fi
    if ! [[ -f "$name.txt" ]]; then
        jq --raw-output \
            < "$name.json" \
            '.entries[]|[.id,.title]|join(" ")' \
            | sed 's|^|https://youtube.com/watch?v=|' \
            > "$name.txt"
    fi
}

main "$@"
