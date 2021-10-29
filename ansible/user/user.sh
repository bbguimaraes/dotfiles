#!/bin/bash
set -euo pipefail

ansible-playbook \
    --inventory localhost, \
    --connection local \
    ansible/user/user.yaml \
    "$@"
