#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
PACMAN_FILE="$DOTFILES_DIR/packages/pacman.txt"
AUR_FILE="$DOTFILES_DIR/packages/aur.txt"

echo "==> Instalando paquetes oficiales..."

mapfile -t pacman_packages < "$PACMAN_FILE"

if [ "${#pacman_packages[@]}" -gt 0 ]; then
    sudo pacman -Syu --needed "${pacman_packages[@]}"
fi

echo "==> Instalando yay..."

if ! command -v yay >/dev/null 2>&1; then
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    cd "$tmp_dir/yay"
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf "$tmp_dir"
fi

echo "==> Instalando paquetes AUR..."

if [ -f "$AUR_FILE" ] && [ -s "$AUR_FILE" ]; then
    mapfile -t aur_packages < "$AUR_FILE"

    if [ "${#aur_packages[@]}" -gt 0 ]; then
        yay -S --needed "${aur_packages[@]}"
    fi
fi

echo "==> Instalando oh-my-zsh..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "==> Instalando plugins y tema de oh-my-zsh..."

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
fi

echo "==> Copiando configuraciones..."

mkdir -p "$HOME/.config"
cp -r "$DOTFILES_DIR/config/." "$HOME/.config/"

echo "==> Copiando archivos del home..."

for file in "$DOTFILES_DIR"/home/.[!.]* "$DOTFILES_DIR"/home/..?*; do
    [ -e "$file" ] || continue
    cp "$file" "$HOME/"
done

echo "==> Instalación completa."
echo "==> Si usas zsh como shell principal, ejecuta: chsh -s /bin/zsh"
echo "==> Luego reinicia sesión."
