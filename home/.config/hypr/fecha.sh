#!/bin/sh
# Fecha en español sin depender del locale del sistema (para hyprlock).
# Ej.: "domingo, 1 de noviembre"
set -- domingo lunes martes miércoles jueves viernes sábado
shift "$(date +%w)"; dia=$1
set -- enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre
shift "$(( $(date +%-m) - 1 ))"; mes=$1
printf '%s, %s de %s\n' "$dia" "$(date +%-d)" "$mes"
