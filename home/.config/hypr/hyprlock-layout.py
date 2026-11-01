#!/usr/bin/env python3
"""Genera ~/.config/hypr/hyprlock-layout.conf con tamaños adaptados a cada monitor.

hyprlock usa tamaños en píxeles físicos: el mismo "56 px" se ve enorme en un
monitor 1080p y pequeño en uno 2560x1600. Aquí se calcula un factor por monitor
(alto en píxeles / alto de referencia) para que todo ocupe la misma proporción
de pantalla en cualquier monitor.

Se ejecuta antes de bloquear (waybar/power/action.sh) y al cambiar el fondo.
"""
import json
import os
import subprocess

REF_HEIGHT = 1600   # laptop (2560x1600): ahí los tamaños de abajo se ven bien
OUT = os.path.expanduser("~/.config/hypr/hyprlock-layout.conf")

# Diseño de referencia (en píxeles a REF_HEIGHT). Orden de arriba a abajo:
#   hora · fecha · usuario · contraseña
CLOCK_SIZE, CLOCK_Y = 96, 170
DATE_SIZE, DATE_Y = 18, 80
USER_SIZE, USER_Y = 14, -10
FIELD_W, FIELD_H, FIELD_Y = 340, 58, -75
FIELD_ROUND, FIELD_OUTLINE = 18, 2


def monitors():
    try:
        out = subprocess.run(["hyprctl", "-j", "monitors"], capture_output=True, text=True, timeout=5).stdout
        return [(m["name"], m["height"]) for m in json.loads(out)]
    except (OSError, ValueError, subprocess.SubprocessError):
        return []


def block(name, height):
    f = height / REF_HEIGHT
    px = lambda v: max(1, round(v * f))          # tamaños (nunca menos de 1)  # noqa: E731
    pos = lambda v: round(v * f)                 # posiciones (pueden ser negativas)  # noqa: E731
    return f"""
# ---- {name or 'cualquier monitor'} ({height}px de alto, factor {f:.2f}) ----
label {{
    monitor = {name}
    text = $TIME
    font_size = {px(CLOCK_SIZE)}
    font_family = $font Bold
    color = $fg
    position = 0, {pos(CLOCK_Y)}
    halign = center
    valign = center
}}
label {{
    monitor = {name}
    text = cmd[update:60000] ~/.config/hypr/fecha.sh
    font_size = {px(DATE_SIZE)}
    font_family = $font
    color = $fg_dim
    position = 0, {pos(DATE_Y)}
    halign = center
    valign = center
}}
label {{
    monitor = {name}
    text = 󰀄  $USER
    font_size = {px(USER_SIZE)}
    font_family = $font
    color = $fg
    position = 0, {pos(USER_Y)}
    halign = center
    valign = center
}}
input-field {{
    monitor = {name}
    size = {px(FIELD_W)}, {px(FIELD_H)}
    outline_thickness = {px(FIELD_OUTLINE)}
    rounding = {px(FIELD_ROUND)}
    inner_color = $bg
    outer_color = $border
    check_color = $accent
    fail_color = rgb(ff5d73)
    font_color = $fg
    font_family = $font
    placeholder_text = <span foreground="##ffffff99">Contraseña…</span>
    fail_text = Contraseña incorrecta
    dots_size = 0.25
    dots_spacing = 0.35
    dots_center = true
    fade_on_empty = false
    position = 0, {pos(FIELD_Y)}
    halign = center
    valign = center
}}
"""


def main():
    mons = monitors()
    text = "# Generado por hyprlock-layout.py — no editar a mano\n"
    if mons:
        text += "".join(block(n, h) for n, h in mons)
    else:                       # sin Hyprland (p. ej. en el instalador): diseño de referencia
        text += block("", REF_HEIGHT)
    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, OUT)


if __name__ == "__main__":
    main()
