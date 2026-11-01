#!/usr/bin/env bash
# Escape: si hay resultados, los cierra (y borra el texto); si no y está en el centro, cierra el reproductor
mon=$(hyprctl -j cursorpos | python3 -c "
import json,sys,subprocess
c=json.load(sys.stdin)
for m in json.loads(subprocess.check_output(['hyprctl','-j','monitors'])):
    if m['x']<=c['x']<m['x']+m['width']/m['scale'] and m['y']<=c['y']<m['y']+m['height']/m['scale']:
        print(m['name']);break")
n=$(eww get view | python3 -c "import json,sys;print(json.load(sys.stdin)['n'])")
if eww active-windows | grep -q spotify-center; then
  win=spotify-center
  if [ "$n" = "0" ]; then eww close spotify-center; exit 0; fi
else
  win=spotify-popup
fi
eww close $win
python3 ~/.config/eww/scripts/nav.py clear
eww open $win --screen "${mon:-eDP-1}"
