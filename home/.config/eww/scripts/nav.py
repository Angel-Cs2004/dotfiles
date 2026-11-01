#!/usr/bin/env python3
# Estado y navegación por filas: resultados (si hay) / sonido / reproducción
import sys, json, os, subprocess
STATE = os.path.expanduser("~/.cache/eww-spotify/state.json")
ROWF = os.path.expanduser("~/.cache/eww-spotify/row")
VIEW = 5          # resultados visibles a la vez
TRACK_H = 240     # alto de la barra lateral (px)
def load():
    try: s = json.load(open(STATE))
    except Exception: s = {}
    s.setdefault("items", []); s.setdefault("sel", -1); s.setdefault("off", 0); s.setdefault("row", "playback")
    if s["row"] == "results" and not s["items"]: s["row"] = "volume"
    return s
def publish(s):
    items, sel, off = s["items"], s["sel"], s["off"]
    n = len(items)
    win = [dict(it, sel=(off + i == sel)) for i, it in enumerate(items[off:off + VIEW])]
    th = max(20, int(TRACK_H * min(1, VIEW / n))) if n else 0
    tt = int((TRACK_H - th) * off / max(1, n - VIEW)) if n > VIEW else 0
    view = {"items": win, "n": n, "sel": sel, "row": s["row"], "thumb_h": th, "thumb_top": tt}
    open(ROWF, "w").write(s["row"])
    subprocess.run(["eww", "update", "view=" + json.dumps(view)])
def save(s):
    json.dump(s, open(STATE, "w")); publish(s)
def move(s, d):
    n = len(s["items"])
    s["sel"] = max(0, min(n - 1, (0 if s["sel"] < 0 else s["sel"]) + d)) if s["sel"] >= 0 or d > 0 else 0
    if s["sel"] < s["off"]: s["off"] = s["sel"]
    if s["sel"] >= s["off"] + VIEW: s["off"] = s["sel"] - VIEW + 1
if __name__ == "__main__":
    cmd = sys.argv[1]; s = load(); n = len(s["items"])
    rows = ["search"] + (["results"] if n else []) + ["volume", "playback", "seek"]
    if cmd == "publish": publish(s)
    elif cmd == "setrow":
        s["row"] = sys.argv[2]; save(s)
    elif cmd == "clear": save({"items": [], "sel": -1, "off": 0, "row": "playback"})
    elif cmd in ("up", "down"):
        i = rows.index(s["row"]) if s["row"] in rows else len(rows) - 1
        s["row"] = rows[max(0, min(len(rows) - 1, i + (1 if cmd == "down" else -1)))]
        if s["row"] == "results" and s["sel"] < 0: s["sel"] = 0
        save(s)
    elif cmd in ("left", "right"):
        if s["row"] == "results" and n:
            move(s, 1 if cmd == "right" else -1); save(s)
    elif cmd == "scroll" and n > VIEW:
        d = 1 if sys.argv[2] == "down" else -1
        s["off"] = max(0, min(n - VIEW, s["off"] + d)); save(s)
    elif cmd == "queue":
        if s["row"] == "results" and 0 <= s["sel"] < n:
            subprocess.Popen(["python3", os.path.join(os.path.dirname(os.path.abspath(__file__)), "enqueue.py"), s["items"][s["sel"]]["id"]])
    elif cmd == "enter":
        if s["row"] == "results" and n:
            if s["sel"] < 0: s["sel"] = 0; save(s)
            subprocess.run(["playerctl", "-p", "spotify", "open", "spotify:track:" + s["items"][s["sel"]]["id"]])
        elif s["row"] == "playback":
            subprocess.run(["playerctl", "-p", "spotify", "play-pause"])
