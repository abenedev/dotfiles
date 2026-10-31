#!/bin/bash
# Lock the screen. The GPG passphrase cache and the SSH agent keys are flushed while locked and restored once hyprlock is unlocked.
pidof hyprlock > /dev/null && exit 0

~/.local/bin/gpg-unlock.sh --lock
~/.local/bin/ssh-unlock.sh --lock
hyprlock && ~/.local/bin/gpg-unlock.sh --keyring && ~/.local/bin/ssh-unlock.sh --keyring
