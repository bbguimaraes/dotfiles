#!/bin/bash
set -euo pipefail

exec perl -E 'say "-" x `tput cols`'
