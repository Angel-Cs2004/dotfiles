#!/usr/bin/env bash
# Trae la ventana de Spotify (oculta o no) al workspace actual y la enfoca
eww close spotify-popup 2>/dev/null
ws=$(hyprctl -j activeworkspace | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")
hyprctl dispatch "hl.dsp.window.move({ workspace = $ws, window = \"class:^(Spotify|spotify)\$\" })" >/dev/null
hyprctl dispatch 'hl.dsp.focus({ window = "class:^(Spotify|spotify)$" })' >/dev/null
