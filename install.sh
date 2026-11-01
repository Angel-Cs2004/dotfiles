#!/usr/bin/env bash
# =============================================================================
#  Instalador de los dotfiles de yizens (Arch Linux + Hyprland)
#
#  ./install.sh               instalación completa (pregunta qué grupos instalar)
#  ./install.sh --dry-run     muestra lo que haría, sin tocar nada
#  ./install.sh --yes         acepta las opciones por defecto, sin preguntas
#  ./install.sh --only-config solo enlaza la configuración (sin paquetes ni sudo)
#  ./install.sh --check       revisa que todo esté bien instalado y enlazado
#
#  Es seguro repetirlo: lo que ya está hecho se salta, y cualquier archivo
#  que vaya a ser reemplazado se mueve antes a ~/.dotfiles-backup/<fecha>/.
# =============================================================================
set -Eeuo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.dotfiles-backup/$STAMP"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG="$LOG_DIR/install-$STAMP.log"
MIN_HYPRLAND="0.56.0"   # la config está en Lua: requiere Hyprland reciente

DRY=0 YES=0 ONLY_CONFIG=0 CHECK=0
FAILED_PKGS=() WARNINGS=()

# ---------------------------------------------------------------- utilidades
c_blue=$'\e[1;34m' c_green=$'\e[1;32m' c_yellow=$'\e[1;33m' c_red=$'\e[1;31m' c_dim=$'\e[2m' c_off=$'\e[0m'
step() { printf '\n%s==>%s %s\n' "$c_blue" "$c_off" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$c_green" "$c_off" "$*"; }
warn() { printf '  %s!%s %s\n' "$c_yellow" "$c_off" "$*"; WARNINGS+=("$*"); }
die()  { printf '%s✗ %s%s\n' "$c_red" "$*" "$c_off" >&2; exit 1; }

run() {   # ejecuta un comando (o solo lo muestra en --dry-run)
    if ((DRY)); then printf '  %s[dry-run]%s %s\n' "$c_dim" "$c_off" "$*"; return 0; fi
    "$@"
}

ask() {   # ask "pregunta" s|n  -> 0 si sí
    local q=$1 def=${2:-s} ans
    if ((YES)); then [[ $def == s ]]; return; fi
    local hint="[S/n]"; [[ $def == n ]] && hint="[s/N]"
    read -r -p "  ? $q $hint " ans </dev/tty || ans=""
    ans=${ans:-$def}
    [[ ${ans,,} == s* || ${ans,,} == y* ]]
}

version_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]; }

trap 'die "Falló en la línea $LINENO: $BASH_COMMAND  (log: $LOG)"' ERR

usage() { sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

for arg in "$@"; do
    case $arg in
        --dry-run)     DRY=1 ;;
        --yes|-y)      YES=1 ;;
        --only-config) ONLY_CONFIG=1 ;;
        --check)       CHECK=1 ;;
        -h|--help)     usage ;;
        *) die "Opción desconocida: $arg (usa --help)" ;;
    esac
done

# ------------------------------------------------------------- comprobaciones
preflight() {
    step "Comprobaciones previas"
    ((EUID != 0)) || die "No lo ejecutes como root ni con sudo: usa tu usuario normal."
    [[ -f /etc/arch-release ]] || die "Este instalador es solo para Arch Linux."
    [[ -d $REPO/home ]] || die "No encuentro $REPO/home: ¿clonaste el repo completo?"
    ok "Arch Linux, usuario $USER"

    if ((ONLY_CONFIG)); then return; fi
    curl -fsS --max-time 8 -o /dev/null https://archlinux.org \
        || die "Sin internet. Conéctate primero (nmtui o iwctl)."
    ok "Internet"
    if ((!DRY)); then
        sudo -v || die "Se necesita sudo."
        # Mantener sudo vivo mientras dura la instalación
        while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
    fi
}

# -------------------------------------------------------------------- paquetes
read_list() {   # imprime los paquetes de una lista (sin comentarios)
    grep -vE '^\s*(#|$)' "$REPO/packages/$1.txt" | sed 's/\s*#.*//'
}

install_group() {
    local group=$1 off=() aur=() p
    while read -r p; do
        if [[ $p == aur:* ]]; then aur+=("${p#aur:}"); else off+=("$p"); fi
    done < <(read_list "$group")

    # Oficiales: saltar instalados y los que ya no existen en los repos
    local todo=()
    for p in "${off[@]}"; do
        pacman -Qq "$p" &>/dev/null && continue
        if pacman -Si "$p" &>/dev/null; then todo+=("$p")
        else warn "$p no existe en los repositorios (¿renombrado?): se salta"; FAILED_PKGS+=("$p"); fi
    done
    if ((${#todo[@]})); then
        local flags=(--needed); ((YES)) && flags+=(--noconfirm)
        run sudo pacman -S "${flags[@]}" "${todo[@]}" || { warn "pacman falló en el grupo $group"; FAILED_PKGS+=("${todo[@]}"); }
    fi

    # AUR, de a uno: si uno falla, los demás siguen
    for p in "${aur[@]}"; do
        pacman -Qq "$p" &>/dev/null && continue
        local yflags=(-S --needed); ((YES)) && yflags+=(--noconfirm --answerdiff None --answerclean None)
        run yay "${yflags[@]}" "$p" || { warn "No se pudo instalar $p (AUR)"; FAILED_PKGS+=("$p"); }
    done
    ok "Grupo $group listo"
}

ensure_yay() {
    command -v yay &>/dev/null && return
    step "Instalando yay (para paquetes de AUR)"
    run sudo pacman -S --needed --noconfirm git base-devel
    local tmp; tmp=$(mktemp -d)
    run git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && run makepkg -si --noconfirm)
    rm -rf "$tmp"
}

packages() {
    step "Actualizando el sistema (evita actualizaciones parciales)"
    run sudo pacman -Syu --noconfirm
    ensure_yay

    step "Detectando hardware"
    local cpu ucode=""
    cpu=$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')
    [[ $cpu == GenuineIntel ]] && ucode=intel-ucode
    [[ $cpu == AuthenticAMD ]] && ucode=amd-ucode
    [[ -n $ucode ]] && ok "CPU $cpu → $ucode"
    local has_nvidia=0
    local gpus; gpus=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || true)
    [[ ${gpus,,} == *nvidia* ]] && has_nvidia=1
    ((has_nvidia)) && ok "GPU NVIDIA detectada" || ok "Sin GPU NVIDIA"

    step "Paquetes: base (escritorio)"
    install_group base
    [[ -n $ucode ]] && ! pacman -Qq "$ucode" &>/dev/null && run sudo pacman -S --needed --noconfirm "$ucode"

    if ((has_nvidia)) && ask "¿Instalar drivers NVIDIA?" s; then step "Paquetes: nvidia"; install_group nvidia; fi
    ask "¿Instalar apps (navegadores, Spotify, Discord, OBS, oficina…)?" s && { step "Paquetes: apps"; install_group apps; }
    ask "¿Instalar herramientas de desarrollo (VS Code, R, Node, StarUML…)?" s && { step "Paquetes: dev"; install_group dev; }
    ask "¿Instalar LaTeX (~3 GB)?" n && { step "Paquetes: latex"; install_group latex; }
    ask "¿Instalar soporte de impresoras y escáner?" n && { step "Paquetes: printing"; install_group printing; }
    ask "¿Instalar DroidCam y OpenTabletDriver?" n && { step "Paquetes: hardware"; install_group hardware; }
    return 0
}

# ------------------------------------------------------------ enlazar config
link() {   # link <origen en repo> <destino en $HOME>
    local src=$1 dst=$2
    if [[ -L $dst && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then return; fi
    if [[ -e $dst || -L $dst ]]; then
        local rel=${dst#"$HOME"/}
        ((DRY)) || mkdir -p "$(dirname "$BACKUP/$rel")"
        run mv "$dst" "$BACKUP/$rel"
        printf '  %s↺%s respaldo: ~/%s\n' "$c_dim" "$c_off" "$rel"
    fi
    ((DRY)) || mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
    printf '  %s→%s ~/%s\n' "$c_green" "$c_off" "${dst#"$HOME"/}"
}

# Carpetas cuyo CONTENIDO se enlaza archivo por archivo (porque el destino
# también tiene cosas ajenas al repo). Todo lo demás se enlaza como carpeta.
DEEP_DIRS=(.config .local .local/bin .config/systemd .config/systemd/user)

is_deep() { local d; for d in "${DEEP_DIRS[@]}"; do [[ $d == "$1" ]] && return 0; done; return 1; }

# walk <ruta relativa> <acción>: recorre home/ y aplica la acción (link o verify)
# a cada elemento que se enlaza. Respeta el .gitignore.
walk() {
    local rel=$1 action=$2 base entry name
    base="$REPO/home${rel:+/$rel}"
    for entry in "$base"/* "$base"/.[!.]*; do
        [[ -e $entry ]] || continue
        name=${entry#"$REPO/home/"}
        git -C "$REPO" check-ignore -q "home/$name" 2>/dev/null && continue
        if [[ -d $entry ]] && is_deep "$name"; then
            walk "$name" "$action"
        else
            "$action" "$entry" "$HOME/$name"
        fi
    done
    return 0
}

BROKEN=0
verify() {
    local src=$1 dst=$2
    if [[ ! -L $dst || "$(readlink -f "$dst")" != "$(readlink -f "$src")" ]]; then
        printf '  ✗ ~/%s no apunta al repo\n' "${dst#"$HOME"/}"; BROKEN=1
    fi
}

config() {
    step "Enlazando configuración (respaldos en ${BACKUP/#$HOME/\~})"
    walk "" link
    [[ -d $BACKUP ]] && ok "Respaldo guardado" || ok "No hubo nada que respaldar"

    step "Archivos que se copian (cambian con el uso, no se enlazan)"
    local wp="$HOME/.config/waypaper/config.ini"
    if [[ ! -f $wp ]]; then run cp "$REPO/home/.config/waypaper/config.ini.example" "$wp"; ok "waypaper/config.ini creado"
    else ok "waypaper/config.ini ya existe (se conserva)"; fi
    run mkdir -p "$HOME/Wallpapers"
    run cp -n "$REPO"/wallpapers/* "$HOME/Wallpapers/" 2>/dev/null || true
    ok "Fondos en ~/Wallpapers"
    command -v xdg-user-dirs-update &>/dev/null && run xdg-user-dirs-update
    run chmod +x "$REPO"/home/.local/bin/* "$REPO"/home/.config/hypr/*.sh "$REPO"/home/.config/eww/scripts/* 2>/dev/null || true

    # Hook que bloquea commits con secretos
    run git -C "$REPO" config core.hooksPath .githooks
}

# ------------------------------------------------------------------- sistema
system_setup() {
    step "Pantalla de inicio (SDDM)"
    if [[ -d /usr/share/sddm/themes/sddm-astronaut-theme ]]; then
        run sudo install -Dm644 "$REPO/system/etc/sddm.conf.d/theme.conf" /etc/sddm.conf.d/theme.conf
        run sudo install -Dm644 "$REPO/system/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf.user" \
            /usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf.user
        run sudo install -Dm644 "$REPO/wallpapers/mlm_1.jpg" /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/mlm_1.jpg
        ok "Tema astronaut con tu fondo"
    else
        warn "sddm-astronaut-theme no está instalado: SDDM usará el tema por defecto"
    fi

    step "Servicios del sistema"
    local svc
    local dm; dm=$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)
    for svc in sddm NetworkManager bluetooth cups; do
        local units; units=$(systemctl list-unit-files "$svc.service" --no-legend 2>/dev/null || true)
        [[ -n $units ]] || continue
        systemctl is-enabled -q "$svc" 2>/dev/null && { ok "$svc ya activo"; continue; }
        if [[ $svc == sddm && -n $dm && $dm != */sddm.service ]]; then
            warn "Ya hay otro gestor de inicio ($(basename "$dm")). Para usar SDDM: sudo systemctl disable $(basename "$dm") && sudo systemctl enable sddm"
            continue
        fi
        run sudo systemctl enable "$svc" && ok "$svc activado"
    done

    step "Grupos de usuario"
    if [[ " $(id -nG "$USER") " != *" input "* ]]; then
        run sudo usermod -aG input "$USER"; ok "Agregado al grupo input (autoscroll). Vale tras reiniciar sesión."
    else ok "Ya estás en el grupo input"; fi

    step "Shell"
    if [[ $(getent passwd "$USER" | cut -d: -f7) != */zsh ]] && command -v zsh &>/dev/null; then
        run sudo chsh -s "$(command -v zsh)" "$USER"; ok "zsh es tu shell por defecto"
    else ok "zsh ya es tu shell"; fi

    step "Extras fuera de pacman"
    # shellcheck source=packages/extras.sh
    source "$REPO/packages/extras.sh"
    extra_ohmyzsh && ok "oh-my-zsh + powerlevel10k + plugins"
    ask "¿Instalar edge-tts (voz del traductor de sioyek)?" s && extra_uv_tools
    ask "¿Instalar Claude Code (npm)?" s && extra_ai_clis
    ask "¿Instalar el editor Zed?" n && extra_zed
    return 0
}

user_services() {
    step "Servicios de usuario"
    run systemctl --user daemon-reload || { warn "systemd de usuario no disponible (¿sin sesión?)"; return; }
    local unit
    for unit in auto-audio-route autoscroll wired-over-wifi; do
        systemctl --user is-enabled -q "$unit" 2>/dev/null || run systemctl --user enable "$unit.service" || warn "No se pudo activar $unit"
    done
    command -v staruml &>/dev/null && { systemctl --user is-enabled -q staruml-mcp 2>/dev/null || run systemctl --user enable staruml-mcp.service || true; }
    command -v otd-daemon &>/dev/null && { systemctl --user is-enabled -q opentabletdriver 2>/dev/null || run systemctl --user enable opentabletdriver.service || true; }
    ok "Servicios de usuario listos"
}

colors() {
    step "Generando la paleta de colores desde el fondo"
    if command -v matugen &>/dev/null && python3 -c 'import PIL' 2>/dev/null; then
        if run "$HOME/.config/hypr/theme.sh" >/dev/null 2>&1; then ok "Colores generados"
        else warn "No se pudo generar la paleta (se generará al iniciar Hyprland)"; fi
    else
        warn "Falta matugen o python-pillow: los colores se generarán al iniciar Hyprland"
    fi
}

# --------------------------------------------------------------------- check
check() {
    step "Revisando enlaces"
    BROKEN=0
    walk "" verify
    ((BROKEN)) && warn "Hay enlaces rotos o reemplazados: corre ./install.sh --only-config" || ok "Todos los enlaces apuntan al repo"

    step "Revisando dependencias"
    bash "$REPO/scripts/check-deps.sh" || warn "Faltan dependencias (ver arriba)"

    step "Versión de Hyprland"
    local hv; hv=$(pacman -Q hyprland 2>/dev/null | awk '{print $2}' | cut -d- -f1)
    if [[ -z $hv ]]; then warn "Hyprland no está instalado"
    elif version_ge "$hv" "$MIN_HYPRLAND"; then ok "Hyprland $hv"
    else warn "Hyprland $hv es anterior a $MIN_HYPRLAND: la config en Lua no funcionará"; fi

    step "Colores generados"
    [[ -f $HOME/.config/waybar/colors.css ]] && ok "Paleta presente" || warn "Falta la paleta: corre ~/.config/hypr/theme.sh"
}

# ---------------------------------------------------------------------- main
main() {
    mkdir -p "$LOG_DIR"
    exec > >(tee -a "$LOG") 2>&1
    printf '%sDotfiles de yizens%s  —  repo: %s\n' "$c_blue" "$c_off" "$REPO"
    ((DRY)) && printf '%sModo --dry-run: no se modifica nada.%s\n' "$c_yellow" "$c_off"

    if ((CHECK)); then check; exit 0; fi

    preflight
    if ((!ONLY_CONFIG)); then packages; fi
    config
    if ((!ONLY_CONFIG)); then system_setup; fi
    user_services
    colors
    check

    step "Resumen"
    ((${#FAILED_PKGS[@]})) && warn "Paquetes no instalados: ${FAILED_PKGS[*]}"
    if ((${#WARNINGS[@]})); then
        printf '  Avisos: %d (revísalos arriba o en %s)\n' "${#WARNINGS[@]}" "${LOG/#$HOME/\~}"
    else ok "Todo sin avisos"; fi
    [[ -d $BACKUP ]] && printf '  Respaldos: %s\n' "${BACKUP/#$HOME/\~}"
    ((ONLY_CONFIG)) || printf '\n  %sReinicia el equipo para entrar a Hyprland.%s\n' "$c_green" "$c_off"
}

main
