#!/usr/bin/env bash
set -euo pipefail

ANSIBLE=$HOME/src/dotfiles/ansible
IMAGE=vagrant-libvirt

main() {
    [[ "$#" -eq 0 ]] && set -- exec
    local cmd=$1; shift
    case "$cmd" in
    build) build "$@";;
    *) cmd_exec "$cmd" "$@";;
    esac
}

usage() {
    cat >&2 <<EOF
Usage:
    $0 CMD ARG...
    $0 EXEC_ARG...

Commands:

    build ARG...
    exec ARG...
EOF
    return 1
}

build() {
    podman build -t "$IMAGE" "${1-"$ANSIBLE/work/vagrant/"}"
}

cmd_exec() {
    local home
    home=$(vagrant_home)
    podman run -it --rm \
        -e LIBVIRT_DEFAULT_URI \
        -v /var/run/libvirt/:/var/run/libvirt/ \
        -v "$home:/root/.vagrant.d" \
        -v "$(realpath "$PWD"):$PWD" \
        --workdir "$PWD" \
        --network host \
        --entrypoint /bin/bash \
        --security-opt label=disable \
        "$IMAGE" \
        -c 'source ~/env/bin/activate && "$@"' bash vagrant "$@"
}

vagrant_home() {
    if test -v VAGRANT_HOME; then
        echo "$VAGRANT_HOME"
        return
    fi
    local h
    if h=$(getent passwd "$SUDO_USER" | cut --delimiter : --field 6); then
        echo "$h/.vagrant.d"
        return
    fi
    return 1
}

main "$@"
