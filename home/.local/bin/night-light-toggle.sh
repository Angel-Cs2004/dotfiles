#!/usr/bin/env bash
# Modo cálido (luz nocturna) con hyprsunset.
#   night-light-toggle.sh          -> alterna encendido/apagado
#   night-light-toggle.sh status   -> imprime JSON para Waybar

TEMP=4000   # Kelvin: más bajo = más cálido (3000 muy cálido, 5000 suave)

is_on() { pgrep -x hyprsunset >/dev/null; }

if ! command -v hyprsunset >/dev/null; then
    [[ "$1" == "status" ]] && { echo '{"text":"<span face='\''Phosphor-Fill'\'' size='\''large'\''></span>","class":"off","tooltip":"Falta instalar hyprsunset"}'; exit 0; }
    notify-send "Modo cálido" "Falta instalar: sudo pacman -S hyprsunset" 2>/dev/null
    exit 1
fi

if [[ "$1" == "status" ]]; then
    if is_on; then
        echo '{"text":"<span face='\''Phosphor-Fill'\'' size='\''large'\''></span>","class":"on","tooltip":"Modo cálido: activado ('"$TEMP"'K)"}'
    else
        echo '{"text":"<span face='\''Phosphor-Fill'\'' size='\''large'\''></span>","class":"off","tooltip":"Modo cálido: desactivado"}'
    fi
    exit 0
fi

if is_on; then
    pkill -x hyprsunset
    notify-send -t 1500 "Modo cálido" "Desactivado" 2>/dev/null
else
    setsid -f hyprsunset -t "$TEMP" >/dev/null 2>&1
    notify-send -t 1500 "Modo cálido" "Activado (${TEMP}K)" 2>/dev/null
fi

# Refrescar el módulo de Waybar al instante
sleep 0.2
pkill -RTMIN+8 waybar
