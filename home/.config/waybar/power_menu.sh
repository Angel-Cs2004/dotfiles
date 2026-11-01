#!/bin/sh

choice=$(printf "Suspender\nReiniciar\nApagar\n" | rofi -dmenu -i -p "" \
  -theme $HOME/.config/waybar/power_menu.rasi)

case "$choice" in
  "Suspender")
    systemctl suspend
    ;;
  "Reiniciar")
    systemctl reboot
    ;;
  "Apagar")
    systemctl poweroff
    ;;
esac
