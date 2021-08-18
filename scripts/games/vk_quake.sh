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
        --chdir "/home/$COMMON_USER/vkQuake/Quake" \
        ./vkquake;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

install() {
    common_install "$1" \
        base base-devel git libmad libvorbis mesa pulseaudio sdl2 \
        vulkan-headers vulkan-icd-loader vulkan-intel vulkan-tools
}

build() {
    common_exec "$1" \
        --user "$COMMON_USER" \
        --setenv SHELL=$SHELL \
        --chdir /home/"$COMMON_USER" \
        bash -c "$(cat <<'EOF'
set -euo pipefail
[[ -e vkQuake ]] || git clone https://github.com/Novum/vkQuake.git
cd vkQuake/Quake
make
EOF
)"
}

dir=$(dirname "$BASH_SOURCE")
source "$dir/common.sh"
main "$@"
