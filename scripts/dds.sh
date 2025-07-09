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
    brightway) brightway "$@";;
    k8s) k8s "$@";;
    postgresql) postgresql "$@";;
    ssh) cmd_ssh "$@";;
    weechat) exec weechat --dir ~/dds/weechat "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    brightway restore-project FILE [NAME]
    k8s [dev|prod]
    postgresql [ARG...]
    ssh dev|prod ARG...
    weechat [ARG...]
EOF
    return 1
}

brightway() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    restore-project) restore_project "$@";;
    *) usage;;
    esac
}

restore_project() {
    [[ "$#" -gt 0 ]] || usage
    local prog='
import sys, bw2io
a = sys.argv
bw2io.restore_project_directory(
    fp=a[1],
    project_name=a[2] if 2 <= len(a) else None,
)
'
    python -c "$prog" "$@"
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

postgresql() {
    exec postgres -D ~/dds/postgresql/data "$@"
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
