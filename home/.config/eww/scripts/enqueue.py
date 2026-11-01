#!/usr/bin/env python3
# Añade una canción a la cola de Spotify. Uso: enqueue.py <track_id>
import sys, os, json, subprocess, urllib.request, urllib.error
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spot, nav
tid = sys.argv[1]
try:
    tok = spot.user_token()
    h = {"Authorization": "Bearer " + tok}
    devs = json.load(urllib.request.urlopen(urllib.request.Request("https://api.spotify.com/v1/me/player/devices", headers=h), timeout=8))["devices"]
    dev = next((d for d in devs if d["is_active"]), devs[0] if devs else None)      # el reproductor, aunque esté en pausa
    if not dev: sys.exit()
    r = urllib.request.Request(f"https://api.spotify.com/v1/me/player/queue?uri=spotify:track:{tid}&device_id={dev['id']}", data=b"", method="POST",
                               headers={"Authorization": "Bearer " + tok})
    urllib.request.urlopen(r, timeout=8)
except (FileNotFoundError, urllib.error.HTTPError) as e:
    if isinstance(e, FileNotFoundError) or e.code in (401, 403):   # falta permiso: pide autorización otra vez
        subprocess.Popen(["python3", os.path.join(os.path.dirname(os.path.abspath(__file__)), "auth.py")])
    sys.exit()
except Exception:
    sys.exit()
s = nav.load()
for it in s["items"]:
    if it["id"] == tid: it["queued"] = True
nav.save(s)
