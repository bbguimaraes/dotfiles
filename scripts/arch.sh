#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    clean) clean "$@";;
    kernel) kernel "$@";;
    img) img "$@";;
    mirrorlist) mirrorlist "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    clean
    kernel revert
    img [build|push]
    mirrorlist
EOF
    return 1
}

clean() {
    local cmd='bash -s'
    [[ "$(id -u)" -ne 0 ]] && cmd='sudo -s'
    exec $cmd <<EOF
paccache --remove --keep 1
paccache --remove --uninstalled --keep 0
EOF
}

kernel() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    revert) kernel_revert "$@";;
    *) echo >&2 "invalid command: kernel $cmd"; return 1;;
    esac
}

kernel_revert() {
    local cmd v
    v=$(uname -r)
    v=${v/-/.}-$(uname -m)
    echo "$v"
    cmd=()
    [[ "$UID" -eq 0 ]] || cmd=("${cmd[@]}" sudo)
    "${cmd[@]}" pacman -U /var/cache/pacman/pkg/linux-$v.pkg.tar.zst
}

img() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    build) img_build "$@";;
    push) img_push "$@";;
    *) img build "$@"; img push "$@";;
    esac
}

img_build() {
    local dir=${TMPDIR:-/tmp}/arch
    if [[ -e "$dir" ]]; then
        echo >&2 "$dir exists, not overwriting"
        return 1
    fi
    local cmd=(bash -s "$dir")
    [[ "$UID" -eq 0 ]] || cmd=(sudo "${cmd[@]}")
    "${cmd[@]}" <<'EOF'
mkdir "$1/"
pacstrap -c "$1/" base
size=$(du -sb "$1/" | cut -f 1)
tar -C "$1" -c . | pv --size "$size" | pixz > "$1.tar.xz"
EOF
}

img_push() {
    local dir=${TMPDIR:-/tmp}/arch
    local eval_args=$(printf %q 'eval "$@"')
    local and=$(printf %q '&&')
    local cmd=(
        ssh bbguimaraes.com -- sudo bash \
            -c "$eval_args" bash \
            podman import - arch "$and" \
            podman tag arch docker.io/library/arch
    )
    [[ "$UID" -eq 0 ]] && cmd=(runuser -u bbguimaraes -- "${cmd[@]}")
    pv "$dir.tar.xz" | "${cmd[@]}"
}

mirrorlist() {
    local f=/etc/pacman.d/mirrorlist
#    sed --in-place \
    if ! grep --quiet '^## Czechia$' "$f"; then
        echo >&2 "line not found"
        exit 1
    fi
    sed --in-place '/^## Czechia$/,/^$/s/^#//' "$f"
}

main "$@"
