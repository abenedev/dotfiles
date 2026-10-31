#!/bin/bash
# Lock the screen. The GPG passphrase cache is flushed while locked and restored once hyprlock is unlocked.
pidof hyprlock > /dev/null && exit 0

~/.local/bin/gpg-unlock.sh --lock
hyprlock && ~/.local/bin/gpg-unlock.sh --keyring
