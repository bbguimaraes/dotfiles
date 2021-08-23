#!/bin/bash
set -euo pipefail

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == master ]]; then
    echo >&2 'refusing to push master'
    exit 1
fi
helper='!f() { printf password=; pass show comp/github/oauth_token; }; f'
pass show test > /dev/null
git -c "credential.helper=$helper" push --set-upstream github "$branch"
hub pull-request
