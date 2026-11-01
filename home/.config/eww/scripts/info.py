#!/usr/bin/env python3
import json, subprocess, os, hashlib, urllib.request
def pc(*a):
    try:
        return subprocess.run(["playerctl","-p","spotify",*a],capture_output=True,text=True,timeout=2).stdout.strip()
    except Exception:
        return ""
status = pc("status")
if not status:
    print(json.dumps({"running":False,"status":"","title":"","artist":"","art":"","shuffle":"Off","loop":"None","pct":0,"posf":"0:00","lenf":"0:00"})); raise SystemExit
title = pc("metadata","xesam:title"); artist = pc("metadata","xesam:artist")
url = pc("metadata","mpris:artUrl")
try: L = int(pc("metadata","mpris:length"))/1e6
except: L = 0
try: p = float(pc("position"))
except: p = 0
art = ""
if url:
    f = os.path.expanduser("~/.cache/eww-spotify/" + hashlib.md5(url.encode()).hexdigest() + ".jpg")
    if not os.path.exists(f):
        try:
            urllib.request.urlretrieve(url.replace("open.spotify.com","i.scdn.co"), f)
        except Exception:
            f = ""
    art = f
fmt = lambda s: f"{int(s)//60}:{int(s)%60:02d}"
tid = pc("metadata","mpris:trackid").split("/")[-1]
liked = False
try:
    cf = os.path.expanduser("~/.cache/eww-spotify/cur_liked.json")
    c = json.load(open(cf)) if os.path.exists(cf) else {}
    if c.get("tid") != tid:
        import sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import spot
        c = {"tid": tid, "liked": bool(spot.liked([tid])[0])}
        json.dump(c, open(cf, "w"))
    liked = c["liked"]
except Exception:
    pass
try: vol = float(pc("volume"))*100
except: vol = 0
print(json.dumps({"running":True,"vol":vol,"liked":liked,"tid":tid,"shuffle":pc("shuffle"),"loop":pc("loop"),"status":status,"title":title,"artist":artist,"art":art,
  "pct":(p/L*100 if L else 0),"posf":fmt(p),"lenf":fmt(L)}))
