#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    install) install "$@";;
    build) build "$@";;
    shell) common_shell "$@";;
    run) common_shell "$@" \
        wine '.wine/drive_c/GOG Games/Assassins Creed/AssassinsCreed_Game.exe';;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

install() {
    common_install "$1" \
        base lib32-libpulse lib32-mesa-libgl lib32-vulkan-intel libunwind \
        wine winetricks
}

build() {
    common_exec "$1" \
        --user "$COMMON_USER" \
        winetricks dlls d3dcompiler_47
}

dir=$(dirname "$BASH_SOURCE")
source "$dir/common.sh"
main "$@"
