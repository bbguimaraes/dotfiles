#!/bin/sh
set -eu

[ "$#" -eq 1 ] || { echo >&2 Usage: $0 name; exit 1; }
f=$(basename "$1")
exec openvpn --daemon --config "/etc/openvpn/client/$f"
