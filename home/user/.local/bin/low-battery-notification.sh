#!/bin/bash
# Low battery notification. Shows a critical notification when on battery under THRESHOLD%.
# Once dismissed (clicked), it stays quiet until AC is plugged in or the session restarts.
# Plugging in AC closes it right away. Checks every INTERVAL seconds and on every power
# supply (udev) event. Started once from Hyprland's startup.

THRESHOLD=20
INTERVAL=60

runtime="${XDG_RUNTIME_DIR:-/tmp}"
exec 9>"$runtime/low-battery-notification.lock"
flock -n 9 || exit 0

id_file="$runtime/low-battery-notification.id"
pid=""       # notify-send process waiting on the displayed notification
dismissed=0  # set once the user closed the notification, cleared on AC

ac_online() {
    for ac in /sys/class/power_supply/A*; do
        [ "$(cat "$ac/online" 2>/dev/null)" = "1" ] && return 0
    done
    return 1
}

capacity() {
    for bat in /sys/class/power_supply/BAT*; do
        cat "$bat/capacity" 2>/dev/null && return
    done
    echo 100
}

shown() { [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; }

show() {
    # --wait keeps notify-send alive until the notification is closed
    notify-send --urgency=critical --print-id --wait "Low battery" "Plug in the power cable" \
        >"$id_file" 9>&- &
    pid=$!
}

close() {
    local id
    id=$(head -n1 "$id_file" 2>/dev/null)
    [ -n "$id" ] && gdbus call --session --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification "$id" >/dev/null 2>&1
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    pid=""
}

check() {
    if ac_online; then
        dismissed=0
        shown && close
        return
    fi
    # notify-send exited without us closing it: the user dismissed it
    if [ -n "$pid" ] && ! shown; then
        dismissed=1
        pid=""
    fi
    if [ "$(capacity)" -lt "$THRESHOLD" ] && [ "$dismissed" = 0 ] && ! shown; then
        show
    fi
}

# fd 9 (the lock) is closed in children so a leftover process can't block a restart
exec 8< <(udevadm monitor --udev --subsystem-match=power_supply 9>&-)
monitor=$!
trap 'shown && close; kill "$monitor" 2>/dev/null' EXIT
trap 'exit 0' INT TERM HUP

while true; do
    check
    read -r -t "$INTERVAL" _ <&8
    rc=$?
    if [ "$rc" -gt 0 ] && [ "$rc" -le 128 ]; then
        sleep "$INTERVAL"  # udev monitor is gone, fall back to polling
    fi
    while read -r -t 0.5 _ <&8; do :; done  # drain the event burst
done
