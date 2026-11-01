#!/bin/sh
# Arranque de la barra: si aún no existen los colores (PC recién instalada), se generan primero.
if [ ! -f "$HOME/.config/waybar/colors.css" ]; then
    "$HOME/.config/hypr/theme.sh" >/dev/null 2>&1
fi
exec waybar
