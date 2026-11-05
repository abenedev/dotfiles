#!/bin/bash
# pinentry-program for gpg-agent: run pinentry-gtk as a native Wayland window.
# gpg-agent passes --display, which forces GTK onto X11, where the passphrase goes through XWayland.
set -euo pipefail

args=()
while (($#)); do
    case "$1" in
        --display)
            shift
            (($#)) && shift
            ;;
        *)
            args+=("$1")
            shift
            ;;
    esac
done

exec /usr/bin/pinentry-gtk "${args[@]}"
