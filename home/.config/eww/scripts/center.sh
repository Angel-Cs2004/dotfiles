#!/usr/bin/env bash
# Super+N: abre/cierra el reproductor en el centro del monitor donde está el mouse
if eww active-windows 2>/dev/null | grep -q spotify-center; then
  eww close spotify-center; python3 ~/.config/eww/scripts/nav.py clear; exit 0
fi
pgrep -x spotify >/dev/null || hyprctl dispatch 'hl.dsp.exec_cmd("spotify", { workspace = "special:spotify silent" })' >/dev/null
eww close spotify-popup 2>/dev/null
mon=$(hyprctl -j cursorpos | python3 -c "
import json,sys,subprocess
c=json.load(sys.stdin)
for m in json.loads(subprocess.check_output(['hyprctl','-j','monitors'])):
    if m['x']<=c['x']<m['x']+m['width']/m['scale'] and m['y']<=c['y']<m['y']+m['height']/m['scale']:
        print(m['name']);break")
python3 ~/.config/eww/scripts/nav.py setrow search
eww open spotify-center --screen "${mon:-eDP-1}"
