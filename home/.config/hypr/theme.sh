#!/bin/sh
# Genera la paleta de colores a partir del fondo y recarga las apps.
# Uso: theme.sh [ruta-del-fondo]   (sin argumento usa el fondo actual de waypaper)

WALL="$1"
if [ -z "$WALL" ]; then
    WALL="$(sed -n 's/^wallpaper = //p' "$HOME/.config/waypaper/config.ini" | tail -n 1)"
fi
# shellcheck disable=SC2088  # texto literal "~/" de waypaper
case "$WALL" in "~/"*) WALL="$HOME/${WALL#\~/}" ;; esac
[ -f "$WALL" ] || { echo "No existe el fondo: $WALL" >&2; exit 1; }

# 1) Paleta estética (OKLCH, intensidad con techo/piso) -> JSON
PAL="${XDG_CACHE_HOME:-$HOME/.cache}/theme/palette.json"
mkdir -p "$(dirname "$PAL")" "$HOME/.config/dunst" "$HOME/.config/zsh"
python3 -I "$HOME/.config/matugen/palette.py" "$WALL" > "$PAL.tmp" && mv "$PAL.tmp" "$PAL" || exit 1

# 2) matugen rellena las plantillas con esa paleta
SRC="$(sed -n 's/.*"source": "\(#[0-9a-fA-F]*\)".*/\1/p' "$PAL")"
matugen -q --import-json "$PAL" color hex "${SRC:-#c41047}" || exit 1

# Tamaños de la pantalla de bloqueo según los monitores conectados
python3 -I "$HOME/.config/hypr/hyprlock-layout.py" 2>/dev/null

# Recargar
# waybar recarga colors.css sola (reload_style_on_change)
pkill -x dunst                      # se reabre solo con la siguiente notificación
hyprctl reload >/dev/null
pkill -SIGUSR1 -x kitty             # recarga kitty.conf (incluye colors.conf)
command -v eww >/dev/null && eww reload >/dev/null 2>&1
# rofi lee colors.rasi cada vez que se abre: no necesita recarga

# Las recargas son "mejor esfuerzo": si una app no está abierta no es un error
exit 0
