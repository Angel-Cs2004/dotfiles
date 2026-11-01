#!/usr/bin/env bash
# Lanzador de apps (Super + D) con 3 diseños: grid | spotlight | full
#   launcher.sh              abre el diseño guardado en ./launcher/style
#   launcher.sh spotlight    prueba un diseño sin cambiar el guardado
#   launcher.sh --set full   guarda el diseño por defecto
DIR="$(cd "$(dirname "$0")" && pwd)/launcher"
STYLE_FILE="$DIR/style"

if [[ ${1:-} == --set ]]; then
    case ${2:-} in grid|spotlight|full) echo "$2" > "$STYLE_FILE"; notify-send -u low "Lanzador" "Diseño: $2"; exit 0 ;;
    *) echo "Diseños: grid, spotlight, full" >&2; exit 1 ;; esac
fi
style=${1:-$(cat "$STYLE_FILE" 2>/dev/null || echo grid)}

# Super + D funciona como interruptor
if pidof rofi >/dev/null; then pkill -x rofi; exit 0; fi

common=(-show drun -matching fuzzy -sort -sorting-method fzf -drun-match-fields "name,generic,keywords,exec")
# En las cuadrículas, ← → mueven entre apps (Ctrl+b / Ctrl+f mueven el cursor del texto)
grid_keys=(-kb-move-char-back "Control+b" -kb-move-char-forward "Control+f" -kb-row-left "Left" -kb-row-right "Right")

case $style in
    grid)
        exec rofi "${common[@]}" "${grid_keys[@]}" -theme "$DIR/grid.rasi" ;;
    spotlight)
        fmt=$'{name}\n<span size=\'small\' alpha=\'60%\'>{generic}</span>'
        exec rofi "${common[@]}" -theme "$DIR/spotlight.rasi" -eh 2 -drun-display-format "$fmt" ;;
    full)
        # Márgenes según el monitor para que la cuadrícula quede centrada y proporcionada
        read -r w h < <(hyprctl -j monitors | python3 -c 'import json,sys; m=[m for m in json.load(sys.stdin) if m["focused"]][0]; print(int(m["width"]/m["scale"]), int(m["height"]/m["scale"]))')
        cols=7; side=$(( (w - cols * 150 - (cols - 1) * 18) / 2 )); ((side < 40)) && side=40
        top=$(( h * 10 / 100 ))
        exec rofi "${common[@]}" "${grid_keys[@]}" -theme "$DIR/full.rasi" \
            -theme-str "mainbox { padding: ${top}px ${side}px 40px ${side}px; } listview { columns: $cols; }" ;;
    *) echo "Diseño desconocido: $style (grid, spotlight, full)" >&2; exit 1 ;;
esac
