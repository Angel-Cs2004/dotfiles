#!/usr/bin/env bash
setsid -f python3 ~/.config/eww/scripts/add.py "$@" >/dev/null 2>&1
