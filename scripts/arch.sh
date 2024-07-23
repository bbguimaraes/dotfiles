#!/bin/bash
set -euo pipefail

PKG_PATH_FMT=/var/cache/pacman/pkg/linux-%s.pkg.tar.zst
ARCHIVE_URL_FMT=https://archive.archlinux.org/packages/l/linux/linux-%s.pkg.tar.zst

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
    local cmd cmds orphan
    cmd='bash -s'
    [[ "$(id -u)" -ne 0 ]] && cmd='sudo -s'
    cmds=$(cat <<EOF
paccache --remove --keep 1
paccache --remove --uninstalled --keep 0
EOF
)
    orphan=$(pacman -Qqtd | paste --serial --delimiter ' ')
    if [[ "$orphan" ]]; then
        cmds="$cmds
pacman --noconfirm -Rsu $orphan
"
    fi
    exec $cmd <<EOF
$cmds
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
    local cmd v f
    v=$(kernel_version)
    cmd=()
    [[ "$UID" -eq 0 ]] || cmd=(sudo)
    f=$(kernel_revert_download "$v")
    "${cmd[@]}" pacman -U "$f"
}

kernel_version() {
    local v
    v=$(uname -r)
    v=${v/-/.}-$(uname -m)
    echo "$v"
}

kernel_revert_download() {
    local v=$1 url; shift
    local f=$(printf "$PKG_PATH_FMT" "$v")
    if [[ ! -f "$f" ]]; then
        url=$(printf "$ARCHIVE_URL_FMT" "$v")
        "$@" curl "$url" -o "$f"
    fi
    echo "$f"
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
set -euo pipefail
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
    local f=/etc/pacman.d/mirrorlist x
    local l=(Italy 'United States')
    for x in "${l[@]}"; do
        if ! grep --quiet "^## $x$" "$f"; then
            echo >&2 "line not found: $x"
            exit 1
        fi
    done
    for x in "${l[@]}"; do
        sed --in-place "/^## $x$/"',/^$/s/^#//' "$f"
    done
}

main "$@"
