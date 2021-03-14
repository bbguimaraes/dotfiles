#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=${1:-}; shift; }
    case "$cmd" in
    push) push "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;
    esac
}

push() {
    local addr=192.168.0.59 port=2121 user=anonymous root=/storage/emulated/0
    for x; do
        echo "$x"
        curl "ftp://$addr:$port/$root/" \
            --user "$user:" \
            --upload-file "$x"
    done
}

main "$@"
