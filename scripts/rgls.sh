#!/bin/sh
set -euo pipefail

rg --files-with-matches "$@" | sort
