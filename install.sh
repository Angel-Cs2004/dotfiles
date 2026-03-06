#!/usr/bin/env bash

set -e

DOTFILES="$HOME/dotfiles"

echo "Instalando paquetes oficiales..."

sudo pacman -Syu --needed - < "$DOTFILES/packages/pacman.txt"

echo "Instalando yay (AUR helper)..."

if ! command -v yay &> /dev/null
then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

echo "Instalando paquetes AUR..."

yay -S --needed - < "$DOTFILES/packages/aur.txt"

echo "Copiando configuraciones..."

mkdir -p ~/.config
cp -r "$DOTFILES/config/"* ~/.config/

echo "Copiando archivos home..."

cp "$DOTFILES/home/.bashrc" ~/

echo "Instalación completa."
