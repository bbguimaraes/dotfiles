#!/usr/bin/env bash
set -euo pipefail

DIR=${XDG_CONFIG_DIR:-$HOME/.config}/bbguimaraes/cd
target=${1:-$HOME}
target=$(readlink --canonicalize "$target")
len=${#HOME}
[[ "${target::$len + 1}" != "$HOME/" ]] && exit
target=${target:$(($len+1))}
file=$DIR/$target.sh
[[ -e "$file" ]] && cat "$file"
