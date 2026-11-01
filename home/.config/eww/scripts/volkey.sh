#!/usr/bin/env bash
# $1 = + o -  : cambia el volumen de Spotify y actualiza la barra al instante
playerctl -p spotify volume "0.05$1"
eww update vol="$(playerctl -p spotify volume | awk '{printf "%d", $1*100}')"
