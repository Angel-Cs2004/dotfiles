#!/usr/bin/env bash
# $1 = segundos (+5 / -5). Acumula las pulsaciones, muestra el destino en la barra y salta UNA vez al soltar
P=/tmp/eww-seek-pending; T=/tmp/eww-seek-last; L=/tmp/eww-seek-lock; B=/tmp/eww-seek-base
preview() {   # base + pendiente -> barra y tiempo
  read -r base len < $B
  awk -v b="$base" -v d="$(cat $P)" -v l="$len" 'BEGIN{
    n=b+d; if(n<0)n=0; if(l>0&&n>l)n=l;
    printf "{\"on\":true,\"pct\":%.2f,\"posf\":\"%d:%02d\"}", (l>0?n/l*100:0), n/60, n%60}' | xargs -0 -I{} eww update prev={}
}
if mkdir $L 2>/dev/null; then               # primera pulsación de la tanda
  echo 0 > $P
  echo "$(playerctl -p spotify position) $(playerctl -p spotify metadata mpris:length | awk '{print $1/1e6}')" > $B
  first=1
fi
echo $(( $(cat $P 2>/dev/null || echo 0) + $1 )) > $P
date +%s%N > $T
preview
[ -n "$first" ] || exit 0
(
  while :; do
    sleep 0.1
    (( $(date +%s%N) - $(cat $T) > 350000000 )) && break
  done
  pend=$(cat $P)
  read -r base len < $B
  playerctl -p spotify position "$(awk -v p="$base" -v d="$pend" 'BEGIN{n=p+d; if(n<0)n=0; printf "%.2f", n}')"
  eww poll sp
  sleep 0.25
  eww update prev='{"on":false,"pct":0,"posf":""}'
  rmdir $L
) >/dev/null 2>&1 &
