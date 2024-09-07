#!/bin/bash
set -euo pipefail

CMDS=(complete image local remote)
VOL=/mnt/bbguimaraes1-vol

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    complete) cmd_complete;;
    image) image "$@";;
    local) _local "$@";;
    remote) remote "$@";;
    synapse) synapse "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    complete
    files ARG...
    image pull|push NAME
    local [sync-docs]
    remote git
    remote pull [force]
    remote compare-files
    remote sync-files [ARG...]
    synapse mount
EOF
    return 1
}

cmd_complete() {
    local line=($COMP_LINE)
    local n=${#line[@]}
    case "$n" in
    1) compgen -W "${CMDS[*]}";;
    2) compgen -W "${CMDS[*]}" "${line[$((n - 1))]}";;
    esac
}

image() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    pull) image_pull "$@";;
    push) image_push "$@";;
    *) usage;;
    esac
}

image_pull() {
    [[ "$#" -eq 1 ]] || usage
    ssh bbguimaraes.com sudo podman save --format oci-archive "$1" \
        | pv | sudo podman load
}

image_push() {
    [[ "$#" -eq 1 ]] || usage
    local cmd=(podman save "$1")
    [[ "$UID" -eq 0 ]] || cmd=(sudo "${cmd[@]}")
    "${cmd[@]}" \
        | pv --cursor | pixz | pv --cursor \
        | ssh bbguimaraes@bbguimaraes.com 'xzcat | sudo podman load'
}

_local() {
    if [[ "$#" -eq 0 ]]; then
        cd ~/src/bbguimaraes.com/bbguimaraes.com
        exec python -m http.server
    fi
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    sync-docs) local_sync_docs "$@";;
    *) echo >&2 "invalid command: local $cmd"; return 1;;
    esac
}

local_sync_docs() {
    local dst=$HOME/src/bbguimaraes.com/bbguimaraes.com/files
    local src=$HOME/src
    local cmd=(rsync --archive --delete)
    local x
    for x in codex nngn; do
        "${cmd[@]}" "$src/$x/docs/html/" "$dst/$x/docs" "$@"
    done
}

remote() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    compare-files) remote_compare_files "$@";;
    git) remote_git "$@";;
    pull) remote_pull "$@";;
    sync-files) remote_sync_files "$@";;
    *) echo >&2 "invalid command: remote $cmd"; return 1;;
    esac
}

remote_git() {
    local cmd=(sudo git -C "$VOL/bbguimaraes.com" "$@")
    exec ssh bbguimaraes.com $(printf '%q\n' "${cmd[@]}")
}

remote_pull() {
    [[ "$#" -eq 0 ]] && { remote_git pull; return; }
    local cmd=$1; shift
    case "$cmd" in
    force) remote_pull_force "$@";;
    *) usage;;
    esac
}

remote_pull_force() {
    [[ "$#" -eq 0 ]] || usage
    ssh bbguimaraes.com bash -c $(printf '%q\n' "$(cat <<EOF
set -euo pipefail
cd "$VOL/bbguimaraes.com"
s=\$(sudo git status --short --untracked=no)
if [[ "\$s" ]]; then
    echo >&2 "\$s"
    echo >&2 'refusing to overwrite local changes'
    exit 1
fi
sudo git fetch --all
sudo git reset --hard origin/master
EOF
)")
}

remote_compare_files() {
    remote_sync_files --verbose --dry-run
}

remote_sync_files() {
    [[ "$#" -eq 0 ]] && set -- --progress --rsync-path 'sudo rsync'
    local host=bbguimaraes.com
    local src=$HOME/src/bbguimaraes.com/bbguimaraes.com/files
    local dst=$VOL/bbguimaraes.com/bbguimaraes.com/
    exec rsync \
        --archive --chown 0:0 \
        "$src" "$host:$dst" "$@"
}

synapse() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    mount) synapse_mount "$@";;
    *) usage;;
    esac
}

synapse_mount() {
    [[ "$#" -eq 0 ]] || usage
    local d=$HOME/synpase
    mkdir --parent "$d"
    if ! [[ -s "$d" ]]; then
        echo >&2 "refusing to mount over non-empty directory $d"
        return 1
    fi
    sshfs \
        -o sftp_server='/usr/bin/sudo /usr/libexec/openssh/sftp-server' \
        -o reconnect \
        "bbguimaraes.com:$VOL/synapse" "$d"
}

main "$@"
