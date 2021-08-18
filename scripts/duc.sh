#!/bin/bash
set -euo pipefail

user=$USER
cmd='bash -s'
[[ "$user" == root ]] && { user=bbguimaraes; cmd="sudo $cmd"; }
db=$(getent passwd "$user" | cut -d : -f 6)/.duc.db
exec $cmd "$user" "$db" <<'EOF'
duc index --database "$2" /
chown -R "$1": "$2"
EOF
