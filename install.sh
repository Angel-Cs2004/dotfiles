#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
PACMAN_FILE="$DOTFILES_DIR/packages/pacman.txt"
AUR_FILE="$DOTFILES_DIR/packages/aur.txt"

is_installed() {
  pacman -Qi "$1" >/dev/null 2>&1
}

echo "==> 📦 Instalando paquetes oficiales (saltando los que ya están)..."
if [ -f "$PACMAN_FILE" ]; then
  mapfile -t all_pacman <"$PACMAN_FILE"
  to_install=()
  for pkg in "${all_pacman[@]}"; do
    if ! is_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done
  if [ "${#to_install[@]}" -gt 0 ]; then
    sudo pacman -Syu --needed "${to_install[@]}"
  fi
fi

echo "==> 🛠️ Verificando yay..."
if ! command -v yay >/dev/null 2>&1; then
  tmp_dir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
  cd "$tmp_dir/yay" && makepkg -si --noconfirm
  cd "$DOTFILES_DIR" && rm -rf "$tmp_dir"
fi

echo "==> 💎 Instalando paquetes AUR faltantes..."
if [ -f "$AUR_FILE" ] && [ -s "$AUR_FILE" ]; then
  mapfile -t all_aur <"$AUR_FILE"
  to_install_aur=()
  for pkg in "${all_aur[@]}"; do
    if ! is_installed "$pkg"; then
      to_install_aur+=("$pkg")
    fi
  done
  if [ "${#to_install_aur[@]}" -gt 0 ]; then
    yay -S --needed "${to_install_aur[@]}"
  fi
fi

# --- AQUÍ ESTÁ EL CAMBIO IMPORTANTE ---

echo "==> 📂 Aplicando personalización de .config (Sobrescribiendo)..."
mkdir -p "$HOME/.config"
# Usamos -a (archivo) y -v (visual). ESTO REEMPLAZARÁ LO VIEJO POR LO DE TU REPO.
if command -v rsync >/dev/null 2>&1; then
  rsync -av "$DOTFILES_DIR/config/" "$HOME/.config/"
else
  cp -rf "$DOTFILES_DIR/config/." "$HOME/.config/"
fi

echo "==> 🏠 Aplicando archivos de la Home (Sobrescribiendo .zshrc, etc)..."
for file in "$DOTFILES_DIR"/home/.[!.]* "$DOTFILES_DIR"/home/..?*; do
  [ -e "$file" ] || continue
  # Copiamos a la fuerza (-f) para que tu configuración sea la que mande
  cp -f "$file" "$HOME/"
  echo "Actualizado: $(basename "$file")"
done

echo "==> ✨ ¡Proceso completado! Tu laptop ahora es un espejo de tu PC."
