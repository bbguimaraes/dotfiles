#!/bin/bash
set -euo pipefail

CMDS=(archive archived audio dailywire play update watched)
VIM=(vim -c 'set buftype=nofile' -c 'set nowrap' -)
VIDEOS=(subs videos --fields yt_id,url,title)

main() {
    local cmd=unwatched
    [[ "$#" -ne 0 ]] && { local cmd=$1; shift; }
    case "$cmd" in
    archive) awk '/^\s/{print$1}' | xargs subs tag archive --;;
    archived) "${VIDEOS[@]}" --tags archive | "${VIM[@]}";;
    audio) audio "$@";;
    complete) cmd_complete;;
    dailywire) "${VIDEOS[@]}" --tags dailywire --unwatched | "${VIM[@]}";;
    open) open "$@";;
    download) download "$@";;
    enqueue)
        subs videos --unwatched --untagged --flat --fields url \
            | xargs celluloid --enqueue;;
    play)
        find -maxdepth 1 -type f -exec ls -tr {} + \
            | xargs --delimiter $'\n' mpv;;
    set-timestamp) set_timestamp "$@";;
    timestamp) timestamp "$@";;
    unwatched)
        # XXX
        cd ~/src/subs
        subs lua 'videos{watched = false, fmt = "url_text"}' \
            | "${VIM[@]}";;
    update) exec subs -vv update "$@";;
    watched) awk '{print$1}' | xargs subs watched;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD ARG...]

Commands:

    archive
    archived
    audio FILE...
    complete
    dailywire
    open type id
    download [N_PROC]
    enqueue
    play ARG...
    set-timestamp DB_FILE ID TS
    timestamp ID...
    unwatched
    update ARG...
    watched
EOF
    return 1
}

audio() {
    local x
    for x; do
        ffmpeg -threads "$(nproc)" -i "$x" -vn "${x%.*}.ogg" &
    done
    wait -p $(jobs -p)
}

cmd_complete() {
    local line=($COMP_LINE)
    local n=${#line[@]}
    case "$n" in
    1) compgen -W "${CMDS[*]}";;
    2) compgen -W "${CMDS[*]}" "${line[$((n - 1))]}";;
    esac
}

open() {
    [[ "$#" -eq 2 ]] || usage
    local type=$1 id=$2
    case "$type" in
    1)
        local j url
        j=$(lbrynet claim search --claim_id "$id")
        if [[ "${j:0:1}" != '{' ]]; then
            echo >&2 "invalid lbrynet output: $j"
            return 1
        fi
        url=$(jq --raw-output '.items[0].canonical_url' <<< $j)
        if [[ "$url" == null ]]; then
            echo >&2 no URL
            return 1
        fi
        url=$(sed <<< $url \
            -e 's,^lbry://,https://odysee.com/,' \
            -e 's/#/:/' \
            -e 's/#c$//')
        exec xdg-open "$url";;
    2) exec firefox --private-window "https://youtube.com/watch?v=$id";;
    *) echo >&2 "invalid type: $type"; return 1;;
    esac
}

download() {
    local n=${1-0}
    awk '{print $3}' \
        | xargs --max-args 1 --max-procs "$n" \
            youtube-dl
#            bash -c 'while ! "$@" && [[ "$?" -le 128 ]]; do sleep 1; done' \
#            bash youtube-dl
}

set_timestamp() {
    [[ "$#" -eq 3 ]] || usage
    local db=$1 id=$2 ts=$3
    sqlite3 "$db" "update videos set timestamp = $ts where yt_id == '$id'"
}

timestamp() {
    python3 -c "$(cat <<'EOF'
import datetime
import sys
import yt_dlp as youtube_dl
class logger(object):
    warning = lambda _, *x: print(*x, file=sys.stderr)
    error = lambda _, *x: print(*x, file=sys.stderr)
    debug = lambda *_: None
ytdl = youtube_dl.YoutubeDL({"logger": logger()})
for id in sys.stdin:
    try:
        info = ytdl.extract_info(
           f"https://www.youtube.com/watch?v={id}",
           download=False)
    except youtube_dl.utils.DownloadError as ex:
        s = str(ex)
        if (
            "Video unavailable" in s
            or "This video is unavailable" in s
            or "This live stream recording is not available" in s
            or "members-only content" in s
            or "Premieres in " in s
            or "Sign in to confirm your age" in s
            or "Sign in if you've been granted access to this video" in s
            or "who has blocked it on copyright grounds" in s
            or "This video has been removed for violating YouTube's" in s
        ):
            print("0")
            continue
        print(f"failed to get information for {id}:", file=sys.stderr)
        raise
    d = datetime.datetime.strptime(info["upload_date"], "%Y%m%d")
    print(str(int(d.timestamp())))
EOF
)"
}

main "$@"
