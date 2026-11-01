#!/bin/sh
# Cambia el fondo con waypaper (que a su vez ejecuta theme.sh y cambia los colores).
# Uso: wallpaper.sh next | prev | random

DIR="$HOME/Wallpapers"
CONF="$HOME/.config/waypaper/config.ini"

current="$(sed -n 's/^wallpaper = //p' "$CONF" | tail -n 1)"
# shellcheck disable=SC2088  # texto literal "~/" de waypaper
case "$current" in "~/"*) current="$HOME/${current#\~/}" ;; esac

list="$(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)"
count="$(printf '%s\n' "$list" | grep -c .)"
[ "$count" -eq 0 ] && { notify-send -u low "Fondos" "No hay imágenes en $DIR"; exit 1; }

case "${1:-next}" in
    next)   new="$(printf '%s\n' "$list" | grep -Fx -A1 "$current" | sed -n 2p)"
            [ -z "$new" ] && new="$(printf '%s\n' "$list" | head -n 1)" ;;
    prev)   new="$(printf '%s\n' "$list" | grep -Fx -B1 "$current" | sed -n 1p)"
            [ -z "$new" ] || [ "$new" = "$current" ] && new="$(printf '%s\n' "$list" | tail -n 1)" ;;
    random) new="$(printf '%s\n' "$list" | grep -Fxv "$current" | shuf -n 1)"
            [ -z "$new" ] && new="$current" ;;
    *)      echo "Uso: $0 next|prev|random" >&2; exit 1 ;;
esac

# Olas tipo agua: ancho,alto de cada ola y curva suave (entra lento, acelera, frena)
export AWWW_TRANSITION_WAVE="45,28"
export AWWW_TRANSITION_BEZIER="0.45,0,0.25,1"

waypaper --wallpaper "$new" >/dev/null 2>&1
notify-send -u low -i "$new" "Fondo de pantalla" "$(basename "$new")"
