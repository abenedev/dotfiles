#!/bin/bash
# Suspend only when running on battery (used by hypridle).
for ac in /sys/class/power_supply/A*; do
    [ "$(cat "$ac/online" 2>/dev/null)" = "1" ] && exit 0
done
systemctl suspend
