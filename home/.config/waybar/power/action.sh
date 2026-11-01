#!/usr/bin/env bash
# Ejecuta una acción de energía. Pide confirmación para las destructivas.
# Uso: action.sh lock|logout|suspend|reboot|poweroff
DIR="$(cd "$(dirname "$0")" && pwd)"

confirm() {   # confirm "Texto"  -> 0 si el usuario acepta
    local ans
    ans=$(printf '%s\n%s\n' "󰄬  Sí" "󰅖  No" | rofi -dmenu -i -p "" -mesg "$1" \
        -theme "$DIR/confirm.rasi" -selected-row 1 \
        -kb-custom-1 "s" -kb-custom-2 "n")
    local rc=$?
    [[ $rc -eq 10 ]] && return 0          # tecla s
    [[ $rc -ne 0 ]] && return 1           # Esc o tecla n
    [[ $ans == "󰄬"* ]]
}

# Antes de bloquear: recalcular tamaños según los monitores conectados
lock_now() {
    python3 -I "$HOME/.config/hypr/hyprlock-layout.py" 2>/dev/null
    pidof hyprlock >/dev/null || hyprlock
}

case "${1:-}" in
    lock)
        if command -v hyprlock >/dev/null; then lock_now
        else notify-send -u low "Bloquear" "Instala hyprlock para bloquear la pantalla"; fi ;;
    logout)
        confirm "¿Cerrar la sesión?" || exit 0
        if command -v hyprshutdown >/dev/null; then hyprshutdown
        else hyprctl dispatch 'hl.dsp.exit()' >/dev/null; fi ;;
    suspend)
        command -v hyprlock >/dev/null && { lock_now & sleep 0.8; }
        systemctl suspend ;;
    reboot)
        confirm "¿Reiniciar el equipo?" && systemctl reboot ;;
    poweroff)
        confirm "¿Apagar el equipo?" && systemctl poweroff ;;
    *) echo "Uso: $0 lock|logout|suspend|reboot|poweroff" >&2; exit 1 ;;
esac
