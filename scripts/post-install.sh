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

# --- Apps ---------------------------------------------------------------------
echo "==> Installing VSCode"
yay -S --noconfirm visual-studio-code-bin

echo "==> Installing Discord"
yay -S --noconfirm discord

echo "==> Installing Claude CLI"
# requires Node.js
sudo pacman -S --noconfirm nodejs npm
sudo npm install -g @anthropic-ai/claude-code

echo ""
echo "Done! Run 'Hyprland' to start the desktop."
