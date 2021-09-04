#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
ansible-playbook \
    --inventory localhost, \
    --connection local \
    --become \
    ansible/install.yaml \
    "$@"
