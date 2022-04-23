#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    clean-files) clean_files "$@";;
    url) url "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 cmd

Commands:

    clean-files
    url ID...
EOF
    return 1
}

clean_files() {
    local j
    j=$(lbrynet status)
    [[ "$j" == "Could not connect to daemon. Are you sure it's running?" ]] \
        && { echo "$j" >&2; return 1; }
    while :; do
        j=$(lbrynet file list)
        [[ "$(jq <<< "$j" '.total_items')" -eq 0 ]] && break
        jq <<< "$j" --raw-output '.items[].claim_id' \
            | xargs -I {} lbrynet file delete --claim_id {}
    done
}

url() {
    local x j name url ext
    for x; do
        j=$(lbrynet claim search --claim_ids "$x")
        name=$(jq --raw-output '.items[0].value.title' <<< $j)
        url=$(jq --raw-output '.items[0].permanent_url' <<< $j)
        ext=$(jq --raw-output '.items[0].value.source.name' <<< $j)
        if [[ "$ext" == null ]]; then
            ext=$(jq --raw-output '.items[0].value.source.media_type' <<< $j)
            if [[ "$ext" == null ]]; then
                echo >&2 "$x: no extension found"
                return 1
            elif [[ "$ext" != video/* ]]; then
                echo >&2 "$x: not a video file: $ext"
                return 1
            fi
            ext=${ext#video/}
        else
            ext=${ext##*.}
        fi
        echo "$url $ext $name"
    done
}

main "$@"
