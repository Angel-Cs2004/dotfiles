# Utilidades de la API de Spotify con tu cuenta (Tus me gusta)
import os, json, base64, time, urllib.request, urllib.parse, urllib.error
CRED = os.path.expanduser("~/.config/eww/spotify_credentials")
USER = os.path.expanduser("~/.cache/eww-spotify/user.json")
UTOK = os.path.expanduser("~/.cache/eww-spotify/user_token.json")
def user_token():
    try:
        t = json.load(open(UTOK))
        if t["exp"] > time.time() + 30: return t["token"]
    except Exception: pass
    c = dict(l.strip().split("=", 1) for l in open(CRED) if "=" in l)
    rt = json.load(open(USER))["refresh_token"]       # FileNotFoundError si no se autorizó
    req = urllib.request.Request("https://accounts.spotify.com/api/token",
        data=urllib.parse.urlencode({"grant_type": "refresh_token", "refresh_token": rt}).encode(),
        headers={"Authorization": "Basic " + base64.b64encode(f"{c['CLIENT_ID']}:{c['CLIENT_SECRET']}".encode()).decode()})
    d = json.load(urllib.request.urlopen(req, timeout=8))
    json.dump({"token": d["access_token"], "exp": time.time() + d["expires_in"]}, open(UTOK, "w"))
    return d["access_token"]
def _call(method, urls, tok):
    for u in urls:
        try:
            r = urllib.request.Request(u, data=b"" if method != "GET" else None, method=method,
                                       headers={"Authorization": "Bearer " + tok})
            return json.load(urllib.request.urlopen(r, timeout=8)) if method == "GET" else (urllib.request.urlopen(r, timeout=8) and True)
        except urllib.error.HTTPError: continue
    raise RuntimeError("api")
def liked(ids):
    if not ids: return []
    tok = user_token()
    return _call("GET", [f"https://api.spotify.com/v1/me/library/contains?uris=" + ",".join("spotify:track:" + i for i in ids),
                         f"https://api.spotify.com/v1/me/tracks/contains?ids=" + ",".join(ids)], tok)
def set_liked(tid, on):
    tok = user_token(); m = "PUT" if on else "DELETE"
    _call(m, [f"https://api.spotify.com/v1/me/library?uris=spotify:track:{tid}",
              f"https://api.spotify.com/v1/me/tracks?ids={tid}"], tok)
