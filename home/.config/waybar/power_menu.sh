#!/bin/sh
# Super + P y el botón ⏻ de Waybar llaman a este archivo.
# El menú está en ./power/ (3 diseños: icons, full, panel).
exec "$HOME/.config/waybar/power/menu.sh" "$@"
