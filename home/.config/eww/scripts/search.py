#!/usr/bin/env python3
# Busca canciones con la API de Spotify (client credentials) y las muestra en el popup
import sys, json, os, time, base64, hashlib, urllib.request, urllib.parse, subprocess
from concurrent.futures import ThreadPoolExecutor
CRED = os.path.expanduser("~/.config/eww/spotify_credentials")
TOKEN = os.path.expanduser("~/.cache/eww-spotify/token.json")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nav, spot
def upd(v):
    s = nav.load(); s.update(items=v, sel=-1, off=0); nav.save(s)
q = " ".join(sys.argv[1:]).strip()
QF = os.path.expanduser("~/.cache/eww-spotify/last_query")
open(QF, "w").write(q)
if not q:
    upd([]); sys.exit()
if os.environ.get("DEBOUNCE", "1") == "1":
    time.sleep(0.2)                       # espera a que termines de escribir
    if open(QF).read() != q: sys.exit()
try:
    cid = sec = None
    for line in open(CRED):
        k, _, v = line.strip().partition("=")
        if k == "CLIENT_ID": cid = v.strip()
        if k == "CLIENT_SECRET": sec = v.strip()
    tok = None
    try:
        t = json.load(open(TOKEN))
        if t["exp"] > time.time() + 30: tok = t["token"]
    except Exception: pass
    if not tok:
        req = urllib.request.Request("https://accounts.spotify.com/api/token",
            data=b"grant_type=client_credentials",
            headers={"Authorization": "Basic " + base64.b64encode(f"{cid}:{sec}".encode()).decode()})
        d = json.load(urllib.request.urlopen(req, timeout=8))
        tok = d["access_token"]
        json.dump({"token": tok, "exp": time.time() + d["expires_in"]}, open(TOKEN, "w"))
    url = "https://api.spotify.com/v1/search?type=track&limit=10&q=" + urllib.parse.quote(q)
    d = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"Authorization": "Bearer " + tok}), timeout=8))
    items = d["tracks"]["items"]
    def art(t):
        imgs = t["album"]["images"]
        if not imgs: return ""
        u = min(imgs, key=lambda i: i["width"])["url"]
        f = os.path.expanduser("~/.cache/eww-spotify/t_" + hashlib.md5(u.encode()).hexdigest() + ".jpg")
        if not os.path.exists(f):
            try: urllib.request.urlretrieve(u, f)
            except Exception: return ""
        return f
    base = [{"id": x["id"], "title": x["name"], "artist": ", ".join(a["name"] for a in x["artists"]), "art": "", "liked": False, "queued": False} for x in items]
    cache = lambda x: os.path.expanduser("~/.cache/eww-spotify/t_" + hashlib.md5(min(x["album"]["images"], key=lambda i: i["width"])["url"].encode()).hexdigest() + ".jpg") if x["album"]["images"] else ""
    for b_, x in zip(base, items):
        f = cache(x)
        if f and os.path.exists(f): b_["art"] = f
    if open(QF).read() != q: sys.exit()
    upd(base)                                 # primero el texto, ya
    with ThreadPoolExecutor(11) as ex:
        arts = ex.submit(lambda: list(ex.map(art, items)))
        lk = ex.submit(lambda: spot.liked([x["id"] for x in items]))
        try: likes = lk.result()
        except Exception: likes = [False] * len(items)
        arts = arts.result()
    if open(QF).read() != q: sys.exit()
    for b_, a_, l_ in zip(base, arts, likes):
        b_["art"] = a_; b_["liked"] = bool(l_)
    upd(base)                                 # luego portadas y corazones
except FileNotFoundError:
    upd([{"id": "", "title": "Faltan credenciales", "artist": "", "art": "", "liked": False, "queued": False}])
except Exception as e:
    upd([{"id": "", "title": "Error de búsqueda", "artist": str(e)[:30], "art": "", "liked": False, "queued": False}])
