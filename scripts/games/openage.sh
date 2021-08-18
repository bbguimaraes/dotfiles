#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    install) install "$@";;
    build) build "$@";;
    shell) common_shell "$@";;
    run) common_shell "$@" --chdir "/home/$COMMON_USER/openage" bin/run;;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

install() {
    common_install "$1" \
        base base-devel cmake cython eigen git libepoxy opus opusfile \
        pulseaudio python python-jinja python-lz4 python-numpy python-pillow \
        python-pygments python-toml qt5-base qt5-declarative qt5-quickcontrols \
        sdl2 sdl2_image ttf-dejavu
}

build() {
    common_exec "$1" \
        --user "$COMMON_USER" \
        --setenv SHELL=$SHELL \
        --chdir /home/"$COMMON_USER" \
        bash -c "$(cat <<'EOF'
set -euo pipefail
[[ -e openage ]] || git clone https://github.com/SFTtech/openage.git
cd openage
git checkout v0.4.1
./configure --mode=release --download-nyan
make
EOF
)"
}

dir=$(dirname "$BASH_SOURCE")
source "$dir/common.sh"
main "$@"
