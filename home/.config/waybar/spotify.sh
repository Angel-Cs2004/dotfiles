#!/usr/bin/env bash
# Muestra solo Spotify (ignora Chrome, etc.) con barra de progreso
P="playerctl -p spotify"
status=$($P status 2>/dev/null) || { echo '{"text":"","class":"stopped"}'; exit 0; }
title=$($P metadata xesam:title 2>/dev/null)
artist=$($P metadata xesam:artist 2>/dev/null)
len=$($P metadata mpris:length 2>/dev/null || echo 0)
pos=$($P position 2>/dev/null || echo 0)
python3 - "$status" "$title" "$artist" "$len" "$pos" <<'PY'
import sys, json
status, title, artist, length, pos = sys.argv[1:6]
try: L = float(length) / 1e6
except: L = 0
try: p = float(pos)
except: p = 0
fmt = lambda s: f"{int(s)//60}:{int(s)%60:02d}"
w = 14
f = int(w * p / L) if L > 0 else 0
f = max(0, min(w - 1, f))
bar = "━" * f + "●" + "─" * (w - f - 1)
t = f"{title} - {artist}" if artist else title
if len(t) > 34: t = t[:33] + "…"
text = f"{t}  {fmt(p)} {bar} {fmt(L)}"
text = text.replace("&", "&amp;")
print(json.dumps({"text": text, "class": status.lower(), "tooltip": False}))
PY
