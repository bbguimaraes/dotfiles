#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    audio) yt-dlp \
        --extract-audio --audio-format vorbis \
        -o '%(title)s.%(ext)s' "$@";;
    conv) conv "$@";;
    split) ~/n/comp/scripts/split_video.py "$@";;
    compress) compress "$@";;
    playlist) playlist "$@";;
    poster) poster "$@";;
    stabilize) stabilize "$@";;
    subtitles) subtitles "$@";;
    webcam) exec mpv --no-pause /dev/video0;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    audio FILE...
    conv audio FILE
    split < FILE INPUT
    compress FILE ARG...
    playlist URL
    playlist urls URL
    playlist txt NAME URL
    poster TIME SRC DST ARG...
    stabilize FILE [ARG...]
    subtitles URL
    webcam
EOF
    return 1
}

compress() {
    local in=$1; shift
    ffmpeg \
        -threads "$(nproc)" -i "$in" \
        -cpu-used 0 -acodec copy -quality realtime -speed 0 -crf 33 "$@"
}

conv() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    audio) conv_audio "$@";;
    *) echo >&2 "invalid command: conv $cmd"; return 1;;
    esac
}

conv_audio() {
    local in=$1; shift
    local out=${in%.*}.ogg
    [[ -e "$out" ]] \
        || exec ffmpeg -threads "$(nproc)" -i "$in" -cpu-used 0 -vn "$out" "$@"
}

playlist() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    http://|https://) playlist_json "$@";;
    urls) playlist_urls "$@";;
    txt) playlist_txt "$@";;
    *) usage;;
    esac
}

playlist_json() {
    yt-dlp --dump-single-json "$@"
}

playlist_urls() {
    local jq_cmd='
.entries[]
    | ["https://youtube.com/watch?v=" + .id, .title]
    | join(" ")
'
    playlist_json "$@" | jq --raw-output "$jq_cmd"
}

playlist_txt() {
    local name=$1 url=$2; shift 2
    if ! [[ -f "$name.json" ]]; then
        ~/src/yt-dlp/yt-dlp.sh --dump-json --ignore-errors "$url" "$@" \
            > "$name.json"
    fi
    if ! [[ -f "$name.txt" ]]; then
        jq --raw-output \
            '["https://youtube.com/watch?v=" + .id, .title]|join(" ")' \
            < "$name.json" \
            > "$name.txt"
    fi
}

poster() {
    local t=$1 input=$2 output=$3; shift 3
    ffmpeg \
        -threads "$(nproc)" -i "$input" \
        -cpu-used 0 -ss "$t" -vframes 1 "$@" "$output"
}

stabilize() {
    [[ "$#" -eq 0 ]] && usage
    local f=$1; shift
    [[ -e transforms.trf ]] || ffmpeg -i "$f" -vf vidstabdetect -f null -
    ffmpeg -i "$f" -vf vidstabtransform "$@"
}

subtitles() {
    yt-dlp --no-download --write-subs "$@"
}

main "$@"
