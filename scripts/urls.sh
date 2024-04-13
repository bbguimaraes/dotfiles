#!/bin/bash
set -euo pipefail

declare -A L=(
    [posix]=https://pubs.opengroup.org/onlinepubs/9699919799/
)

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    menu) menu "$@";;
    open) open "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD [ARG...]

Commands:

    open URL
    menu
EOF
    return 1
}

menu() {
    local OFS=$'\n' url
    url=$(dmenu <<< ${!L[@]})
    open "$url"
}

open() {
    local url=${L[$1]}
    if [[ "$url" ]]; then
        xdg-open "$url"
    else
        echo >&2 "invalid url: $url"
        return 1
    fi
}

main "$@"
