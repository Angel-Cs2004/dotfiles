#!/usr/bin/env bash
# Verifica que estén instalados todos los comandos que usan los atajos,
# la barra y los scripts. Si falta alguno, dice qué paquete instalar.
set -uo pipefail

# comando : paquete : para qué se usa
deps=(
    "Hyprland:hyprland:el escritorio"
    "waybar:waybar:la barra"
    "dunst:dunst:notificaciones"
    "notify-send:libnotify:enviar notificaciones"
    "rofi:rofi:menú de apps y de apagado"
    "eww:eww-git (AUR):reproductor de Spotify y panel"
    "kitty:kitty:terminal"
    "zsh:zsh:shell"
    "awww:awww:fondo con animación"
    "awww-daemon:awww:fondo con animación"
    "waypaper:waypaper (AUR):selector de fondos"
    "matugen:matugen:colores dinámicos"
    "python3:python:scripts"
    "brightnessctl:brightnessctl:brillo"
    "wpctl:wireplumber:volumen"
    "pactl:libpulse:audio (auto-audio-route)"
    "playerctl:playerctl:teclas multimedia"
    "hyprsunset:hyprsunset:luz nocturna"
    "grim:grim:captura de pantalla"
    "slurp:slurp:captura de región"
    "wl-copy:wl-clipboard:portapapeles"
    "ffplay:ffmpeg:voz del traductor de sioyek"
    "trans:translate-shell:traductor de sioyek"
    "nmcli:networkmanager:red (wired-over-wifi)"
    "dolphin:dolphin:gestor de archivos"
    "yazi:yazi:gestor de archivos en terminal"
    "google-chrome-stable:google-chrome (AUR):navegador de SUPER+B"
    "fastfetch:fastfetch:info del sistema"
)
py_modules=("PIL:python-pillow:paleta de colores" "evdev:python-evdev:autoscroll")
fonts=("JetBrainsMono Nerd Font:ttf-jetbrains-mono-nerd" "Iosevka Nerd Font:ttf-iosevka-nerd")

missing=0
for d in "${deps[@]}"; do
    IFS=: read -r cmd pkg why <<<"$d"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf '✗ %-22s falta → instala %-24s (%s)\n' "$cmd" "$pkg" "$why"; missing=1
    fi
done
for m in "${py_modules[@]}"; do
    IFS=: read -r mod pkg why <<<"$m"
    python3 -c "import $mod" 2>/dev/null || { printf '✗ módulo %-15s falta → instala %-24s (%s)\n' "$mod" "$pkg" "$why"; missing=1; }
done
font_list=$(fc-list : family 2>/dev/null)
for f in "${fonts[@]}"; do
    IFS=: read -r name pkg <<<"$f"
    grep -qiF "$name" <<<"$font_list" || { printf '✗ fuente %-15s falta → instala %s\n' "$name" "$pkg"; missing=1; }
done

if ((missing)); then exit 1; fi
echo "✓ Todas las dependencias están instaladas"
