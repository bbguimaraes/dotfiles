#!/bin/bash
set -euo pipefail

cd ~/src
git clone --origin origin "https://bbguimaraes@git.bbguimaraes.com/$1.git"
git -C "$1" config user.email bbguimaraes@bbguimaraes.com
while read -r name url; do
    git -C "$1" remote add "$name" "$url"
done <<EOF
gitlab https://bbguimaraes@gitlab.bbguimaraes.com/bbguimaraes/$1.git
github https://bbguimaraes@github.com/bbguimaraes/$1.git
EOF
