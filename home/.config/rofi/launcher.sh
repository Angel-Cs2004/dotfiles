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

# Tamaños según el monitor donde se abre (referencia: 1080 px de alto lógico).
# Así los íconos ocupan la misma proporción de pantalla en cualquier monitor.
read -r W H < <(hyprctl -j monitors | python3 -c 'import json,sys; m=[m for m in json.load(sys.stdin) if m["focused"]][0]; print(int(m["width"]/m["scale"]), int(m["height"]/m["scale"]))')
px() { echo $(( $1 * H / 1080 )); }   # escala un valor de referencia

case $style in
    grid)
        exec rofi "${common[@]}" "${grid_keys[@]}" -theme "$DIR/grid.rasi" -theme-str "
            window { width: $(px 640)px; border-radius: $(px 24)px; }
            mainbox { padding: $(px 18)px; spacing: $(px 16)px; }
            listview { spacing: $(px 8)px; }
            element { padding: $(px 12)px $(px 4)px $(px 9)px $(px 4)px; spacing: $(px 8)px; border-radius: $(px 14)px; }
            element-icon { size: $(px 38)px; }" ;;
    spotlight)
        fmt=$'{name}\n<span size=\'small\' alpha=\'60%\'>{generic}</span>'
        exec rofi "${common[@]}" -theme "$DIR/spotlight.rasi" -eh 2 -drun-display-format "$fmt" -theme-str "
            window { width: $(px 600)px; }
            inputbar { padding: $(px 16)px $(px 20)px; }
            element { padding: $(px 7)px $(px 12)px; spacing: $(px 12)px; }
            element-icon { size: $(px 26)px; }" ;;
    full)
        # Cuadrícula centrada: celdas de ~120 px de referencia
        cols=8; cell=$(px 120); gap=$(px 14)
        side=$(( (W - cols * cell - (cols - 1) * gap) / 2 )); ((side < 40)) && side=40
        exec rofi "${common[@]}" "${grid_keys[@]}" -theme "$DIR/full.rasi" -theme-str "
            mainbox { padding: $(( H * 10 / 100 ))px ${side}px 40px ${side}px; spacing: $(px 36)px; }
            inputbar { width: $(px 440)px; padding: $(px 11)px $(px 18)px; }
            listview { columns: $cols; lines: 5; expand: false; spacing: $gap; }
            element { padding: $(px 14)px $(px 6)px $(px 11)px $(px 6)px; spacing: $(px 9)px; border-radius: $(px 18)px; }
            element-icon { size: $(px 48)px; }" ;;
    *) echo "Diseño desconocido: $style (grid, spotlight, full)" >&2; exit 1 ;;
esac
