#!/usr/bin/env bash
# Alterna bucle: None -> Playlist -> Track -> None
case "$(playerctl -p spotify loop)" in
  None) playerctl -p spotify loop Playlist ;;
  Playlist) playerctl -p spotify loop Track ;;
  *) playerctl -p spotify loop None ;;
esac
