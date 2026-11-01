#!/bin/bash
# Run MEGAcmd only on AC power: start it when plugged in, quit it when unplugged.
# Event driven (udev), so it doesn't poll. Started once from Hyprland's startup.

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/mega-power.lock"
flock -n 9 || exit 0

ac_online() {
    for ac in /sys/class/power_supply/A*; do
        [ "$(cat "$ac/online" 2>/dev/null)" = "1" ] && return 0
    done
    return 1
}

last=""
apply() {
    if ac_online; then state=ac; else state=battery; fi
    [ "$state" = "$last" ] && return
    last=$state
    if [ "$state" = ac ]; then
        pgrep -x mega-cmd-server >/dev/null || nohup mega-cmd-server >/dev/null 2>&1 &
    else
        mega-quit >/dev/null 2>&1
    fi
}

apply
udevadm monitor --udev --subsystem-match=power_supply | while read -r _; do
    apply
done
