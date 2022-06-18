#!/bin/bash
set -euo pipefail

exec ansible-playbook \
    --inventory ansible/hosts \
    --limit rmanzarek \
    "$@"
