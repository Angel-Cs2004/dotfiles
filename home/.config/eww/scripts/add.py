#!/usr/bin/env python3
# Alterna "Tus me gusta" para una canción. Uso: add.py <track_id | current>
import sys, os, json, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spot, nav
tid = sys.argv[1]
if tid == "current":
    tid = subprocess.run(["playerctl","-p","spotify","metadata","mpris:trackid"],capture_output=True,text=True).stdout.strip().split("/")[-1]
try:
    now = spot.liked([tid])[0]
    spot.set_liked(tid, not now)
    new = not now
except FileNotFoundError:
    # primera vez: pide autorización en el navegador
    subprocess.Popen(["python3", os.path.join(os.path.dirname(os.path.abspath(__file__)), "auth.py")]); sys.exit()
except Exception:
    sys.exit()
s = nav.load()
for it in s["items"]:
    if it["id"] == tid: it["liked"] = new
nav.save(s)
json.dump({"tid": tid, "liked": new}, open(os.path.expanduser("~/.cache/eww-spotify/cur_liked.json"), "w"))
