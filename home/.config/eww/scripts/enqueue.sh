#!/usr/bin/env bash
setsid -f python3 ~/.config/eww/scripts/enqueue.py "$@" >/dev/null 2>&1
