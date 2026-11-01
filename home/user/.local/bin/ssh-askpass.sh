#!/bin/bash
# SSH_ASKPASS program: ask for the passphrase in a pinentry-gtk window.
# ssh and ssh-add call it with the prompt as argument and read the passphrase from stdout.
set -euo pipefail

desc="${1:-Enter passphrase}"
desc="${desc//%/%25}"  # Assuan percent-escapes
desc="${desc//$'\n'/%0A}"

reply="$(printf 'SETTITLE SSH\nSETDESC %s\nSETPROMPT Passphrase:\nGETPIN\n' "$desc" | /usr/bin/pinentry-gtk)"

while IFS= read -r line; do
    case "$line" in
        "D "*)
            pin="${line#D }"
            printf '%b\n' "${pin//%/\\x}"  # Decode the percent-escapes
            exit 0
            ;;
        ERR*) exit 1 ;;
    esac
done <<< "$reply"
exit 1
