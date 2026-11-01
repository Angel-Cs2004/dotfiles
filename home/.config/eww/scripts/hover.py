#!/usr/bin/env python3
# Abre el popup de Spotify al pasar el mouse por el icono y lo cierra al salir
import json, os, subprocess, time
def sh(*a):
    return subprocess.run(a, capture_output=True, text=True).stdout
ICON = (55, 0, 105, 52)      # x1,y1,x2,y2 relativos al monitor
POP  = (50, 0, 490, 500)     # icono + popup (incluye hueco entre ambos)
def inside(r, x, y): return r[0] <= x <= r[2] and r[1] <= y <= r[3]
outside_since = None
bound = set()
D = os.path.expanduser("~/.config/eww/scripts/")
KEYS = {"Escape": D+"escape.sh", "Up": D+"nav.sh up", "Down": D+"nav.sh down",
        "Left": D+"nav.sh left", "Right": D+"nav.sh right",
        "Return": D+"nav.sh enter", "space": D+"nav.sh queue"}
def unbind(k): subprocess.run(["hyprctl","eval",f"hl.unbind({json.dumps(k)})"], capture_output=True)
def set_binds(want):
    global bound
    for k in want - bound:
        opts = ", { repeating = true }" if k in ("Left", "Right") else ""   # repeating: se repite al mantener
        subprocess.run(["hyprctl","eval",f"hl.bind({json.dumps(k)}, hl.dsp.exec_cmd({json.dumps(KEYS[k])}){opts})"], capture_output=True)
    for k in bound - want: unbind(k)
    bound = set(want)
for k in KEYS: unbind(k)
while True:
    time.sleep(0.12)
    try:
        cur = json.loads(sh("hyprctl", "-j", "cursorpos"))
        mons = json.loads(sh("hyprctl", "-j", "monitors"))
    except Exception:
        continue
    mon = None
    for m in mons:
        w, h = m["width"]/m["scale"], m["height"]/m["scale"]
        if m["x"] <= cur["x"] < m["x"]+w and m["y"] <= cur["y"] < m["y"]+h:
            mon = m; break
    if not mon: continue
    rx, ry = cur["x"]-mon["x"], cur["y"]-mon["y"]
    active = sh("eww", "active-windows")
    center = "spotify-center" in active
    is_open = "spotify-popup" in active
    if center:
        try: v = json.loads(sh("eww","get","view"))
        except Exception: v = {"n": 0, "sel": -1}
        if v.get("row") == "search":      # escribiendo: solo Arriba/Abajo (cambiar de fila) y Escape
            set_binds({"Escape","Up","Down"})
        else:
            set_binds({"Escape","Up","Down","Left","Right","Return"} | ({"space"} if v.get("row") == "results" and v.get("sel", -1) >= 0 else set()))
        if is_open: subprocess.run(["eww","close","spotify-popup"])
        continue
    if is_open:
        try: v = json.loads(sh("eww","get","view"))
        except Exception: v = {"n": 0, "sel": -1}
        if v.get("row") == "search":
            set_binds({"Up","Down"} | ({"Escape"} if v.get("n", 0) > 0 else set()))
        else:
            set_binds({"Up","Down","Left","Right","Return"} | ({"Escape"} if v.get("n", 0) > 0 else set())
                      | ({"space"} if v.get("row") == "results" and v.get("sel", -1) >= 0 else set()))
    else:
        set_binds(set())
    if not is_open:
        outside_since = None
        if inside(ICON, rx, ry) and subprocess.run(["pgrep","-x","spotify"],capture_output=True).returncode == 0:
            subprocess.run(["eww","open","spotify-popup","--screen",mon["name"]])
    else:
        if inside(POP, rx, ry):
            outside_since = None
        else:
            outside_since = outside_since or time.time()
            if time.time() - outside_since > 0.4:
                subprocess.run(["eww","close","spotify-popup"]); subprocess.run(["python3", D+"nav.py", "clear"]); outside_since = None
