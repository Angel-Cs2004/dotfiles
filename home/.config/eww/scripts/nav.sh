#!/usr/bin/env bash
# Despacha las flechas según la fila activa (volumen y reproducción van directo, sin Python)
D=~/.config/eww/scripts
row=$(cat ~/.cache/eww-spotify/row 2>/dev/null || echo playback)
case "$1:$row" in
  left:volume)  "$D/volkey.sh" - ;;
  right:volume) "$D/volkey.sh" + ;;
  left:playback|right:playback)
    f=/tmp/eww-spotify-skip; now=$(date +%s%N); last=$(cat $f 2>/dev/null || echo 0)
    (( now - last < 400000000 )) && exit 0      # no saltar canciones sin parar al mantener
    echo $now > $f
    [ "$1" = left ] && playerctl -p spotify previous || playerctl -p spotify next ;;
  left:seek)  "$D/seekkey.sh" -5 ;;
  right:seek) "$D/seekkey.sh" 5 ;;
  *) setsid -f python3 "$D/nav.py" "$@" >/dev/null 2>&1 ;;
esac
