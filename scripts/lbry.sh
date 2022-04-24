#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    clean-files) clean_files "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 cmd

Commands:

    clean-files
EOF
    return 1
}

clean_files() {
    local j
    while :; do
        j=$(lbrynet file list)
        [[ "$(jq <<< "$j" '.total_items')" -eq 0 ]] && break
        jq <<< "$j" --raw-output '.items[].claim_id' \
            | xargs -I {} lbrynet file delete --claim_id
    done
}

main "$@"
