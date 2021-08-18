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
        --chdir "/home/$COMMON_USER/0ad" \
        binaries/system/pyrogenesis;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

install() {
    common_install "$1" \
        base base-devel boost cmake enet fmt git gloox libpng libsodium \
        libvorbis miniupnpc openal pulseaudio python rust sdl2 wxgtk3
}

build() {
    common_exec "$1" \
        --user "$COMMON_USER" \
        --setenv SHELL=$SHELL \
        --chdir /home/"$COMMON_USER" \
        bash -c "$(cat <<'EOF'
set -euo pipefail
[[ -e 0ad ]] || git clone --depth 5 https://github.com/0ad/0ad.git
cd 0ad
pushd build/workspaces
WX_CONFIG=wx-config-gtk3 ./update-workspaces.sh
pushd gcc
make
EOF
)"
}

dir=$(dirname "$BASH_SOURCE")
source "$dir/common.sh"
main "$@"
