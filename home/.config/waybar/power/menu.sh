#!/usr/bin/env bash
# Menú de energía con 3 diseños: icons | full | panel
#   menu.sh              abre el diseño guardado en ./style
#   menu.sh full         prueba un diseño sin cambiar el guardado
#   menu.sh --set panel  guarda el diseño por defecto (el que abre Super + P)
DIR="$(cd "$(dirname "$0")" && pwd)"
STYLE_FILE="$DIR/style"

if [[ ${1:-} == --set ]]; then
    case ${2:-} in icons|full|panel) echo "$2" > "$STYLE_FILE"; notify-send -u low "Menú de energía" "Diseño: $2"; exit 0 ;;
    *) echo "Diseños: icons, full, panel" >&2; exit 1 ;; esac
fi
style=${1:-$(cat "$STYLE_FILE" 2>/dev/null || echo icons)}

# Si ya hay un menú abierto, cerrarlo (Super + P funciona como interruptor)
if pidof rofi >/dev/null; then pkill -x rofi; exit 0; fi
if eww active-windows 2>/dev/null | grep -q power-panel; then exec "$DIR/panel.sh" close; fi

uptime_txt=$(uptime -p | sed -e 's/^up //' -e 's/ hours\?/ h/' -e 's/ minutes\?/ min/' -e 's/ days\?/ d/')
has_lock=0; command -v hyprlock >/dev/null && has_lock=1

# Opciones: id|ícono|texto|tecla
opts=()
((has_lock)) && opts+=("lock|󰌾|Bloquear|l")
opts+=("logout|󰍃|Salir|e" "suspend|󰤄|Suspender|s" "reboot|󰜉|Reiniciar|r" "poweroff|󰐥|Apagar|p")

run_rofi() {   # run_rofi <tema> <mensaje> <formato de fila>
    local theme=$1 mesg=$2 fmt=$3 extra=${4:-} rows=() keys=() i=1 o id icon label key
    for o in "${opts[@]}"; do
        IFS='|' read -r id icon label key <<<"$o"
        # shellcheck disable=SC2059
        rows+=("$(printf "$fmt" "$icon" "$label")")
        keys+=("-kb-custom-$i" "$key"); ((i++))
    done
    local sel rc
    # Las filas tienen 2 líneas (ícono + texto): se separan con "|" en vez de salto de línea
    sel=$(IFS='|'; printf '%s' "${rows[*]}" | rofi -dmenu -sep '|' -eh 3 -markup-rows -format i -p "${PROMPT:-}" -mesg "$mesg" \
        -theme "$DIR/$theme.rasi" -theme-str "listview { columns: ${#opts[@]}; } $extra" \
        -selected-row $((${#opts[@]} - 3)) \
        -kb-move-char-back "Control+b" -kb-move-char-forward "Control+f" \
        -kb-row-left "Left,h" -kb-row-right "Right" \
        "${keys[@]}")
    rc=$?
    if ((rc >= 10)); then sel=$((rc - 10)); elif ((rc != 0)) || [[ -z $sel ]]; then exit 0; fi
    IFS='|' read -r id _ <<<"${opts[$sel]}"
    exec "$DIR/action.sh" "$id"
}

case $style in
    icons)
        run_rofi icons "<span alpha='70%'>encendido hace $uptime_txt</span>" \
            "<span font='JetBrainsMono Nerd Font 24'>%s</span>\n<span font='JetBrainsMono Nerd Font 9' alpha='75%%'>%s</span>" \
            "window { width: $(( ${#opts[@]} * 112 + 44 ))px; }" ;;
    full)
        user=$(id -un)
        # Margen lateral para que las tarjetas midan ~170 px en cualquier monitor
        mon_w=$(hyprctl -j monitors | python3 -c 'import json,sys; m=[m for m in json.load(sys.stdin) if m["focused"]][0]; print(int(m["width"]/m["scale"]))')
        n=${#opts[@]}; side=$(( (mon_w - n * 170 - (n - 1) * 22) / 2 )); ((side < 20)) && side=20
        avatar=$(python3 -I "$DIR/avatar.py" 2>/dev/null)
        if [[ -n $avatar ]]; then avatar_css="icon-avatar { filename: \"$avatar\"; }"
        else avatar_css="avatar-row { enabled: false; }"; fi
        run_rofi full "$(date +%H:%M)<span font='JetBrainsMono Nerd Font 14' weight='normal'>
Hasta luego, <b>$user</b>  <span alpha='55%'>·  encendido hace $uptime_txt</span></span>" \
            "<span font='JetBrainsMono Nerd Font 30'>%s</span>\n<span font='JetBrainsMono Nerd Font 11'>%s</span>" \
            "listview { margin: 0px ${side}px; } $avatar_css" ;;
    panel)
        exec "$DIR/panel.sh" open ;;
    *) echo "Diseño desconocido: $style (icons, full, panel)" >&2; exit 1 ;;
esac
