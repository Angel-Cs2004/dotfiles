#!/bin/bash
FLAG="/tmp/sioyek_voice_on"
if [ -f "$FLAG" ]; then
    rm "$FLAG"
    [ -f /tmp/sioyek_ffplay_pid ] && kill "$(cat /tmp/sioyek_ffplay_pid)" 2>/dev/null && rm -f /tmp/sioyek_ffplay_pid
    notify-send "Sioyek Traductor" "Voz desactivada" -t 2000 -i audio-volume-muted
else
    touch "$FLAG"
    notify-send "Sioyek Traductor" "Voz activada" -t 2000 -i audio-volume-high
fi
