#!/usr/bin/env bash
# Si Spotify no está abierto, lo inicia; si ya lo está, abre/cierra el popup
if ! pgrep -x spotify >/dev/null; then
  hyprctl dispatch 'hl.dsp.exec_cmd("spotify", { workspace = "special:spotify silent" })' >/dev/null
  exit 0
fi
# abre/cierra el popup de Spotify en el monitor donde está el mouse
if eww active-windows 2>/dev/null | grep -q spotify-popup; then
  exit 0
fi
mon=$(python3 - <<'PY'
import json, subprocess
cur = json.loads(subprocess.check_output(["hyprctl","-j","cursorpos"]))
for m in json.loads(subprocess.check_output(["hyprctl","-j","monitors"])):
    w, h = m["width"]/m["scale"], m["height"]/m["scale"]
    if m["x"] <= cur["x"] < m["x"]+w and m["y"] <= cur["y"] < m["y"]+h:
        print(m["name"]); break
PY
)
if [ -n "$mon" ]; then eww open spotify-popup --screen "$mon"; else eww open spotify-popup; fi
