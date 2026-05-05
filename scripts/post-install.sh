#!/usr/bin/env bash
# Run as your normal user after first boot into Arch.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- Helpers ------------------------------------------------------------------

# Install one or more pacman packages, skipping any already installed.
pkg() {
  local to_install=()
  for p in "$@"; do
    if pacman -Q "$p" &>/dev/null; then
      echo "    [skip] $p"
    else
      to_install+=("$p")
    fi
  done
  [[ ${#to_install[@]} -gt 0 ]] && sudo pacman -S --noconfirm "${to_install[@]}"
}

# Install one or more AUR packages, skipping any already installed.
aur() {
  local to_install=()
  for p in "$@"; do
    if pacman -Q "$p" &>/dev/null; then
      echo "    [skip] $p"
    else
      to_install+=("$p")
    fi
  done
  [[ ${#to_install[@]} -gt 0 ]] && yay -S --noconfirm "${to_install[@]}"
}

# Install a global npm package, skipping if already present.
npm_pkg() {
  if npm list -g --depth=0 "$1" &>/dev/null 2>&1; then
    echo "    [skip] $1"
  else
    sudo npm install -g "$1"
  fi
}

deploy() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "${dst}")"
  cp -r "${src}" "${dst}"
  echo "    ${dst}"
}

# --- yay (AUR helper) ---------------------------------------------------------
if ! command -v yay &>/dev/null; then
  echo "==> Installing yay"
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
fi

# --- Dotfiles -----------------------------------------------------------------
echo "==> Deploying dotfiles"
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
aur visual-studio-code-bin

echo "==> Installing Discord"
aur discord

echo "==> Installing Claude CLI"
pkg nodejs npm
npm_pkg @anthropic-ai/claude-code

# --- Notifications, lock screen, clipboard, wallpaper, system monitor ---------
echo "==> Installing mako (notification daemon)"
pkg mako

echo "==> Installing hyprlock + hypridle (screen lock & idle)"
aur hyprlock hypridle

echo "==> Installing hyprpaper (wallpaper)"
aur hyprpaper

echo "==> Installing cliphist + wl-clipboard (clipboard history)"
pkg wl-clipboard
aur cliphist

echo "==> Installing btop (system monitor)"
pkg btop

echo "==> Installing playerctl (media key support)"
pkg playerctl

echo "==> Installing hyprpicker (color picker)"
aur hyprpicker

# --- Hyprland Extras ----------------------------------------------------------
echo "==> Installing hyprsunset (color temperature / night mode)"
aur hyprsunset

# --- System Utilities ---------------------------------------------------------
echo "==> Installing nwg-displays (monitor config GUI)"
aur nwg-displays

echo "==> Installing ddcutil (external monitor brightness)"
pkg ddcutil

echo "==> Installing ydotool (input automation)"
aur ydotool

echo "==> Installing jq + yq (JSON/YAML tools)"
pkg jq
aur go-yq

# --- Productivity -------------------------------------------------------------
echo "==> Installing thunar (file manager)"
pkg thunar thunar-volman gvfs

echo "==> Installing qalculate (calculator)"
pkg qalculate-gtk

# --- Media & Audio ------------------------------------------------------------
echo "==> Installing easyeffects (audio effects & EQ)"
pkg easyeffects

echo "==> Installing pavucontrol-qt (per-app volume mixer)"
pkg pavucontrol-qt

echo "==> Installing songrec (music recognition)"
aur songrec

# --- Screenshot & Recording ---------------------------------------------------
echo "==> Installing swappy (screenshot annotation)"
pkg swappy

echo "==> Installing wf-recorder (screen recording)"
pkg wf-recorder

echo "==> Installing grim + slurp (screenshot region selection)"
pkg grim slurp

echo "==> Installing tesseract + English data (OCR)"
pkg tesseract tesseract-data-eng

# --- Theming ------------------------------------------------------------------
echo "==> Installing adw-gtk-theme (modern GTK theme)"
aur adw-gtk-theme

echo "==> Installing Bibata cursor theme"
aur bibata-cursor-theme-bin

echo "==> Installing JetBrains Mono Nerd Font"
pkg ttf-jetbrains-mono-nerd

echo "==> Installing Kvantum (Qt theme manager)"
pkg kvantum

echo "==> Installing matugen (Material You wallpaper color generator)"
aur matugen-bin

# --- Bar & Launcher -----------------------------------------------------------
echo "==> Installing fuzzel (app launcher)"
pkg fuzzel

echo "==> Installing cava (audio visualizer)"
pkg cava

# --- Shell & Terminal ---------------------------------------------------------
echo "==> Installing fish shell"
pkg fish

echo "==> Installing zsh"
pkg zsh

echo "==> Installing starship prompt"
pkg starship

echo ""
echo "Done! Run 'Hyprland' to start the desktop."
