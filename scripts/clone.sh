#!/bin/bash
set -euo pipefail

GIT=https://bbguimaraes@git.bbguimaraes.com
GITLAB=https://bbguimaraes@gitlab.bbguimaraes.com/bbguimaraes
GITHUB=https://bbguimaraes@github.com/bbguimaraes
DST=$HOME/src/$1

[[ -e "$DST" ]] || git -C ~/src clone --origin origin "$GIT/$1.git"
cd "$DST"
[[ "$HOSTNAME" == rh* ]] || git config user.email bbguimaraes@bbguimaraes.com
remotes=$(git remote)
while read -r name url; do
    grep --quiet --line-regexp "$name" <<< "$remotes" && continue
    git remote add "$name" "$url"
done <<EOF
gitlab $GITLAB/$1.git
github $GITHUB/$1.git
EOF
