#!/bin/bash

[[ "$#" -gt 0 ]] && sleep "$1"
printf '\a'
exec mpv --no-terminal ~/n/archivum/ping.flac
