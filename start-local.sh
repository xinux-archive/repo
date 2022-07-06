#!/usr/bin/env bash

type pacman 2> /dev/null 1>&2 || {
    echo "You should run it on Arch Linux"
    exit 1
}

CurrentDir="$(cd "$(dirname "${0}")" || exit 1 ; pwd)"
bash "$CurrentDir/scripts/main.sh" "$@"
