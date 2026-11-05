#!/bin/bash
# Never sleep on AC power: while plugged in, hold a systemd-logind block inhibitor on sleep and on the
# lid switch, and release it on battery. Locking and screens turning off still happen (hypridle, lid
# bind), so background processes such as Claude Code remote control sessions keep running.
# Event driven (udev), so it doesn't poll. Started once from Hyprland's startup.

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ac-no-sleep.lock"
flock -n 9 || exit 0

ac_online() {
    for ac in /sys/class/power_supply/A*; do
        [ "$(cat "$ac/online" 2>/dev/null)" = "1" ] && return 0
    done
    return 1
}

inhibitor=""
hold() {
    [ -n "$inhibitor" ] && kill -0 "$inhibitor" 2>/dev/null && return
    systemd-inhibit --what=sleep:handle-lid-switch --mode=block \
        --who="ac-no-sleep" --why="Plugged in: never sleep" \
        sleep infinity 9>&- &
    inhibitor=$!
}
release() {
    [ -z "$inhibitor" ] && return
    pkill -P "$inhibitor" sleep 2>/dev/null  # systemd-inhibit exits with its command, dropping the lock
    inhibitor=""
}
apply() {
    if ac_online; then hold; else release; fi
}

# fd 9 (the lock) is closed in children so a leftover process can't block a restart
exec 8< <(udevadm monitor --udev --subsystem-match=power_supply 9>&-)
monitor=$!
trap 'release; kill "$monitor" 2>/dev/null' EXIT
trap 'exit 0' INT TERM HUP

apply
while read -r _ <&8; do
    apply
done
