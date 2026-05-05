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

deploy "${REPO_DIR}/dotfiles/hypr"    "${HOME}/.config/hypr"
deploy "${REPO_DIR}/dotfiles/kitty"   "${HOME}/.config/kitty"
deploy "${REPO_DIR}/dotfiles/waybar"  "${HOME}/.config/waybar"
deploy "${REPO_DIR}/dotfiles/wofi"    "${HOME}/.config/wofi"
deploy "${REPO_DIR}/dotfiles/mako"    "${HOME}/.config/mako"

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

echo ""
echo "Done! Run 'Hyprland' to start the desktop."
