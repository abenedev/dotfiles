#!/bin/bash
# Preset or flush the GPG passphrase cache of gpg-agent.
# Called when the session locks or unlocks:
#   gpg-unlock.sh --unlock   reads the passphrase from stdin and presets it for every secret key
#   gpg-unlock.sh --lock     flushes every cached passphrase
#   gpg-unlock.sh --keyring  same as --unlock, with the passphrase read from the secret service (libsecret)
set -euo pipefail

case "${1:-}" in
    --lock)
        gpg-connect-agent reloadagent /bye > /dev/null
        ;;
    --unlock)
        preset="$(gpgconf --list-dirs libexecdir)/gpg-preset-passphrase"
        IFS= read -r passphrase
        passphrase="${passphrase%$'\r'}"

        gpg-connect-agent /bye > /dev/null  # Make sure the agent is running
        for keygrip in $(gpg --list-secret-keys --with-keygrip --with-colons | awk -F: '$1 == "grp" { print $10 }'); do
            printf '%s' "$passphrase" | "$preset" --preset "$keygrip"
        done
        ;;
    --keyring)
        secret-tool lookup service gpg-passphrase | "$0" --unlock
        ;;
    *)
        echo "Usage: $0 --unlock | --lock | --keyring" >&2
        exit 1
        ;;
esac
