hl.on("hyprland.start", function()
    hl.exec_cmd("~/.local/bin/theme.sh dark")  -- always start on the dark theme
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("~/.local/bin/ac-no-sleep.sh")  -- blocks sleep & lid suspend while on AC
    hl.exec_cmd("~/.local/bin/low-battery-notification.sh")  -- warns once when low on battery
    hl.exec_cmd("~/.local/bin/mega-power.sh")  -- runs mega-cmd-server only on AC
    hl.exec_cmd("alacritty -e yay -Syu --needed --noconfirm")
end)
