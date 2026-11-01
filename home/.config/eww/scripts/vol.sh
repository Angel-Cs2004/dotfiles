#!/usr/bin/env bash
playerctl -p spotify volume "$(python3 -c "print(float('$1')/100)")"
