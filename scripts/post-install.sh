#!/usr/bin/env bash
# Run as your normal user after first boot into Arch.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- yay (AUR helper) ---------------------------------------------------------
if ! command -v yay &>/dev/null; then
  echo "==> Installing yay"
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
fi

# --- Dotfiles -----------------------------------------------------------------
echo "==> Deploying dotfiles"

deploy() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "${dst}")"
  cp -r "${src}" "${dst}"
  echo "    ${dst}"
}

deploy "${REPO_DIR}/dotfiles/hypr"       "${HOME}/.config/hypr"
deploy "${REPO_DIR}/dotfiles/kitty"      "${HOME}/.config/kitty"
deploy "${REPO_DIR}/dotfiles/waybar"     "${HOME}/.config/waybar"
deploy "${REPO_DIR}/dotfiles/wofi"       "${HOME}/.config/wofi"
deploy "${REPO_DIR}/dotfiles/mako"       "${HOME}/.config/mako"
deploy "${REPO_DIR}/dotfiles/gtk-3.0"    "${HOME}/.config/gtk-3.0"
deploy "${REPO_DIR}/dotfiles/gtk-4.0"    "${HOME}/.config/gtk-4.0"
deploy "${REPO_DIR}/dotfiles/fuzzel"     "${HOME}/.config/fuzzel"
deploy "${REPO_DIR}/dotfiles/cava"       "${HOME}/.config/cava"
deploy "${REPO_DIR}/dotfiles/fish"       "${HOME}/.config/fish"
deploy "${REPO_DIR}/dotfiles/zsh/.zshrc" "${HOME}/.zshrc"
deploy "${REPO_DIR}/dotfiles/starship/starship.toml" "${HOME}/.config/starship.toml"

# --- Apps ---------------------------------------------------------------------
echo "==> Installing VSCode"
yay -S --noconfirm visual-studio-code-bin

echo "==> Installing Discord"
yay -S --noconfirm discord

echo "==> Installing Claude CLI"
# requires Node.js
sudo pacman -S --noconfirm nodejs npm
sudo npm install -g @anthropic-ai/claude-code

# --- Notifications, lock screen, clipboard, wallpaper, system monitor ---------
echo "==> Installing mako (notification daemon)"
sudo pacman -S --noconfirm mako

echo "==> Installing hyprlock + hypridle (screen lock & idle)"
yay -S --noconfirm hyprlock hypridle

echo "==> Installing hyprpaper (wallpaper)"
yay -S --noconfirm hyprpaper

echo "==> Installing cliphist + wl-clipboard (clipboard history)"
sudo pacman -S --noconfirm wl-clipboard
yay -S --noconfirm cliphist

echo "==> Installing btop (system monitor)"
sudo pacman -S --noconfirm btop

echo "==> Installing playerctl (media key support)"
sudo pacman -S --noconfirm playerctl

echo "==> Installing hyprpicker (color picker)"
yay -S --noconfirm hyprpicker

# --- Theming ------------------------------------------------------------------
echo "==> Installing adw-gtk-theme (modern GTK theme)"
yay -S --noconfirm adw-gtk-theme

echo "==> Installing Bibata cursor theme"
yay -S --noconfirm bibata-cursor-theme-bin

echo "==> Installing JetBrains Mono Nerd Font"
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd

echo "==> Installing Kvantum (Qt theme manager)"
sudo pacman -S --noconfirm kvantum

echo "==> Installing matugen (Material You wallpaper color generator)"
yay -S --noconfirm matugen-bin

# --- Bar & Launcher -----------------------------------------------------------
echo "==> Installing fuzzel (app launcher)"
sudo pacman -S --noconfirm fuzzel

echo "==> Installing cava (audio visualizer)"
sudo pacman -S --noconfirm cava

# --- Shell & Terminal ---------------------------------------------------------
echo "==> Installing fish shell"
sudo pacman -S --noconfirm fish

echo "==> Installing zsh"
sudo pacman -S --noconfirm zsh

echo "==> Installing starship prompt"
sudo pacman -S --noconfirm starship

echo ""
echo "Done! Run 'Hyprland' to start the desktop."
