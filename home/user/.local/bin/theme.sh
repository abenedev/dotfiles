#!/bin/bash
# Switch the GTK theme and the wallpaper together.
# Usage: theme.sh [dark|light], without argument it toggles the current theme.
set -euo pipefail

interface=org.gnome.desktop.interface
wallpapers_dir=~/Pictures/Wallpapers

theme="${1:-}"
if [[ -z $theme ]]; then
    if [[ $(gsettings get "$interface" color-scheme) == "'prefer-dark'" ]]; then
        theme=light
    else
        theme=dark
    fi
fi

case "$theme" in
    dark)
        color_scheme=prefer-dark
        gtk_theme=Adwaita-dark  # GTK3 ignores color-scheme, so pinentry & file choosers need this
        wallpaper=fluid.png
        ;;
    light)
        color_scheme=prefer-light
        gtk_theme=Adwaita
        wallpaper=fluid-light.png
        ;;
    *)
        echo "Usage: theme.sh [dark|light]" >&2
        exit 1
        ;;
esac

gsettings set "$interface" color-scheme "$color_scheme"
gsettings set "$interface" gtk-theme "$gtk_theme"

# Fails on startup when hyprpaper isn't up yet, which is fine: it starts on the dark wallpaper
hyprctl hyprpaper wallpaper ",$wallpapers_dir/$wallpaper"
