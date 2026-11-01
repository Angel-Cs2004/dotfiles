#!/usr/bin/env bash
# Programas que NO vienen de pacman/AUR. install.sh carga este archivo
# y llama a cada función según lo que elijas. Todas se pueden repetir sin
# romper nada (si algo ya está instalado, se salta).

# --- oh-my-zsh + powerlevel10k + plugins (necesario para el prompt) ---------
extra_ohmyzsh() {
    local zsh_dir="$HOME/.oh-my-zsh" custom="$HOME/.oh-my-zsh/custom"
    if [[ ! -d $zsh_dir ]]; then
        run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    clone_or_update https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
    clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
    clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
}

# --- Herramientas de Python instaladas con uv (traductor de sioyek) ---------
extra_uv_tools() {
    need uv || return 0
    uv tool list 2>/dev/null | grep -q '^edge-tts ' || run uv tool install edge-tts
}

# --- CLIs de IA (npm global en ~/.local, como en la PC original) -------------
extra_ai_clis() {
    need npm || return 0
    [[ -f $HOME/.npmrc ]] && grep -q '^prefix=' "$HOME/.npmrc" || run npm config set prefix "$HOME/.local"
    command -v claude >/dev/null || run npm install -g @anthropic-ai/claude-code
}

# --- Editor Zed (instalador oficial, va a ~/.local) --------------------------
extra_zed() {
    command -v zed >/dev/null && return 0
    run sh -c "$(curl -fsSL https://zed.dev/install.sh)"
}

# Funciones auxiliares (usan run/log de install.sh) --------------------------
clone_or_update() {
    local url=$1 dir=$2
    if [[ -d $dir/.git ]]; then
        run git -C "$dir" pull --ff-only --quiet || warn "No se pudo actualizar $dir"
    else
        run git clone --depth=1 --quiet "$url" "$dir"
    fi
}

need() {
    command -v "$1" >/dev/null || { warn "Falta '$1': se salta este extra"; return 1; }
}
