#!/bin/sh
# Inicia awww (fondos con transiciones animadas) y pone el último fondo elegido en waypaper.

WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
WALLPAPER="$HOME/Wallpapers/mlm_1.jpg"

w="$(sed -n 's/^wallpaper = //p' "$WAYPAPER_CONFIG" 2>/dev/null | tail -n 1)"
# shellcheck disable=SC2088  # se compara el texto literal "~/" que guarda waypaper
case "$w" in
    "~/"*) WALLPAPER="$HOME/${w#\~/}" ;;
    /*)    WALLPAPER="$w" ;;
esac

pkill -x hyprpaper 2>/dev/null
pgrep -x awww-daemon >/dev/null || awww-daemon >/tmp/awww-daemon.log 2>&1 &

# Esperar a que el daemon responda
for _ in $(seq 1 20); do
    awww query >/dev/null 2>&1 && break
    sleep 0.25
done

awww img "$WALLPAPER" --resize crop --transition-type fade --transition-duration 0.8 --transition-fps 144
