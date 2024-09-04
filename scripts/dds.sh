#!/usr/bin/env bash
set -euo pipefail

INFRA=$HOME/dds/infra
declare -A INVENTORY=(
    [dev]=eu-central-dev
    [prod]=eu-central
)

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    ssh) cmd_ssh "$@";;
    weechat) exec weechat --dir ~/dds/weechat "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    ssh dev|prod ARG...
    weechat [ARG...]
EOF
    return 1
}

cmd_ssh() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    dev|prod) exec ssh \
        -F "$INFRA/inventory/${INVENTORY[$cmd]}/ssh_config" \
        "$@";;
    *) usage;;
    esac
}

main "$@"
