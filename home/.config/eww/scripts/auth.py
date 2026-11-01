#!/usr/bin/env python3
# Autorización única con tu cuenta de Spotify (para el botón +). Ejecútalo una vez.
import os, json, base64, urllib.request, urllib.parse, webbrowser, http.server
CRED = os.path.expanduser("~/.config/eww/spotify_credentials")
OUT = os.path.expanduser("~/.cache/eww-spotify/user.json")
REDIRECT = "http://127.0.0.1:8888/callback"
c = dict(l.strip().split("=", 1) for l in open(CRED) if "=" in l)
url = "https://accounts.spotify.com/authorize?" + urllib.parse.urlencode({
    "client_id": c["CLIENT_ID"], "response_type": "code", "redirect_uri": REDIRECT,
    "scope": "user-library-modify user-library-read user-modify-playback-state user-read-playback-state"})
code = {}
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        code["v"] = q.get("code", [""])[0]
        self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8"); self.end_headers()
        self.wfile.write("<h2>Listo, ya puedes cerrar esta pestaña.</h2>".encode())
    def log_message(self, *a): pass
print("Abriendo el navegador… si no se abre, entra a:\n" + url)
webbrowser.open(url)
s = http.server.HTTPServer(("127.0.0.1", 8888), H)
while "v" not in code: s.handle_request()
req = urllib.request.Request("https://accounts.spotify.com/api/token",
    data=urllib.parse.urlencode({"grant_type": "authorization_code", "code": code["v"], "redirect_uri": REDIRECT}).encode(),
    headers={"Authorization": "Basic " + base64.b64encode(f"{c['CLIENT_ID']}:{c['CLIENT_SECRET']}".encode()).decode()})
d = json.load(urllib.request.urlopen(req))
json.dump({"refresh_token": d["refresh_token"]}, open(OUT, "w")); os.chmod(OUT, 0o600)
print("Autorización guardada.")
