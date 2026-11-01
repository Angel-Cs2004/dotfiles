#!/usr/bin/env bash
# $1 = porcentaje 0-100
len=$(playerctl -p spotify metadata mpris:length) || exit 0
playerctl -p spotify position "$(python3 -c "print(float('$1')/100*$len/1e6)")"
