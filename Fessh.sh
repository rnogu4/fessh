#!/bin/sh
printf '\033c\033]0;%s\a' Fessh
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Fessh.x86_64" "$@"
