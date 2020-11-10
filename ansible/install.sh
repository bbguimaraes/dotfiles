#!/bin/bash
set -euo pipefail

ansible-playbook \
    --inventory localhost, \
    --connection local \
    --become \
    ansible/install.yaml \
    "$@"
