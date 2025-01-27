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
    k8s) k8s "$@";;
    ssh) cmd_ssh "$@";;
    weechat) exec weechat --dir ~/dds/weechat "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    k8s [dev|prod]
    ssh dev|prod ARG...
    weechat [ARG...]
EOF
    return 1
}

k8s() {
    local env
    case "$#" in
    0) ;;
    1) case "$1" in
        dev) env=$cmd;;
    esac;;
    *) usage;;
    esac
    export KUBECONFIG=$HOME/.kube/dds${env+-$env}
    exec bash --login -i
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
