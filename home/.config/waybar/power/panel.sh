#!/usr/bin/env bash
# Diseño 3 · Panel lateral (eww) que entra deslizándose desde la derecha.
# Uso: panel.sh open | close | act <lock|logout|suspend|reboot|poweroff>
DIR="$(cd "$(dirname "$0")" && pwd)"

monitor_under_cursor() {
    hyprctl -j cursorpos | python3 -c '
import json, sys, subprocess
c = json.load(sys.stdin)
for m in json.loads(subprocess.check_output(["hyprctl", "-j", "monitors"])):
    if m["x"] <= c["x"] < m["x"] + m["width"] / m["scale"] and m["y"] <= c["y"] < m["y"] + m["height"] / m["scale"]:
        print(m["name"]); break'
}

info_json() {
    python3 - <<'EOF'
import json, os, glob, socket, subprocess, getpass
up = subprocess.run(["uptime", "-p"], capture_output=True, text=True).stdout.strip()
up = (up.removeprefix("up ").replace(" hours", " h").replace(" hour", " h")
        .replace(" minutes", " min").replace(" minute", " min").replace(" days", " d").replace(" day", " d"))
bat, charging = "", False
for b in glob.glob("/sys/class/power_supply/BAT*"):
    try:
        bat = open(b + "/capacity").read().strip() + "%"
        charging = open(b + "/status").read().strip() in ("Charging", "Full")
    except OSError:
        pass
    break
home = os.path.expanduser("~")
avatar = next((p for p in (home + "/.face", home + "/.face.icon",
                           home + "/.config/fastfetch/logos/milesmorales.png") if os.path.isfile(p)), "")
print(json.dumps({
    "user": getpass.getuser(), "host": socket.gethostname(), "uptime": up,
    "bat": bat or "AC", "charging": charging or not bat, "avatar": avatar,
    "lock": subprocess.run(["sh", "-c", "command -v hyprlock"], capture_output=True).returncode == 0,
}))
EOF
}

close_panel() {
    eww close power-panel power-backdrop >/dev/null 2>&1
    hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1
}

case ${1:-} in
    open)
        mon=$(monitor_under_cursor)
        eww update power_info="$(info_json)"
        eww open power-backdrop --screen "${mon:-0}" >/dev/null
        eww open power-panel --screen "${mon:-0}" >/dev/null
        # Atajos de teclado mientras el panel está abierto (ver submap "power" en hyprland.lua)
        hyprctl dispatch 'hl.dsp.submap("power")' >/dev/null
        ;;
    close)
        close_panel ;;
    act)
        close_panel
        exec "$DIR/action.sh" "${2:-}" ;;
    *) echo "Uso: $0 open|close|act <acción>" >&2; exit 1 ;;
esac
