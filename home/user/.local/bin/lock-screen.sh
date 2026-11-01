#!/bin/bash
# Lock the screen, unless it is already locked. The login keyring is locked too, so secrets are asked again after unlocking.
pidof hyprlock > /dev/null && exit 0

busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service Lock ao 1 /org/freedesktop/secrets/collection/login > /dev/null || true
hyprlock
