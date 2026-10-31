#!/bin/bash
# Load or flush the SSH keys of the ssh-agent.
# Called when the session locks or unlocks:
#   ssh-unlock.sh --lock     removes every key from the agent
#   ssh-unlock.sh --keyring  adds the default keys, with the passphrase read from the secret service (libsecret)
set -euo pipefail

# ssh-add runs this script again as its askpass program, with the prompt as argument
if [ -n "${SSH_UNLOCK_ASKPASS:-}" ]; then
    secret-tool lookup service ssh-passphrase
    exit
fi

case "${1:-}" in
    --lock)
        ssh-add -D > /dev/null 2>&1
        ;;
    --keyring)
        SSH_UNLOCK_ASKPASS=1 SSH_ASKPASS="$0" SSH_ASKPASS_REQUIRE=force ssh-add < /dev/null > /dev/null 2>&1
        ;;
    *)
        echo "Usage: $0 --lock | --keyring" >&2
        exit 1
        ;;
esac
