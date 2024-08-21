#!/usr/bin/env bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    hosts) cmd_hosts "$@";;
    ping) cmd_ping "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    hosts reset-fingerprints FILE [ARG...]
    ping DESTINATION...
EOF
    return 1
}

cmd_hosts() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    reset-fingerprints) hosts_reset_fingerprints "$@";;
    *) usage;;
    esac
}

hosts_reset_fingerprints() {
    [[ "$#" -eq 0 ]] && usage
    local f=$1; shift
    local list x
    list=$(cut --delimiter ' ' --field 1 "$f")
    > "$f"
    for x in $list; do
        ssh "$@" -o StrictHostKeyChecking=accept-new "$x" true
    done
}

cmd_ping() {
    local x
    for x; do
        ssh "$x" true
    done
}

main "$@"
