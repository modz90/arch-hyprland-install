#!/usr/bin/env bash
# Run from the Arch live environment after connecting to Wi-Fi.
# Usage: bash install.sh <drive> <hostname> <username>
#   e.g. bash install.sh sdb mymachine myuser
set -euo pipefail

DRIVE="${1:?Usage: $0 <drive> <hostname> <username>}"
HOSTNAME="${2:?}"
USERNAME="${3:?}"

DEVICE="/dev/${DRIVE}"

echo "==> Target device: ${DEVICE}"
echo "==> Hostname:      ${HOSTNAME}"
echo "==> Username:      ${USERNAME}"
echo ""
echo "WARNING: This will erase ${DEVICE}. Press Enter to continue or Ctrl+C to abort."
read -r

# --- Partition ----------------------------------------------------------------
echo "==> Partitioning ${DEVICE}"
parted -s "${DEVICE}" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 esp on \
  mkpart swap linux-swap 513MiB 4.5GiB \
  mkpart root ext4 4.5GiB 100%

# --- Format -------------------------------------------------------------------
echo "==> Formatting"
mkfs.fat -F32 "${DEVICE}1"
mkswap      "${DEVICE}2"
mkfs.ext4 -F "${DEVICE}3"

# --- Mount --------------------------------------------------------------------
echo "==> Mounting"
mount "${DEVICE}3" /mnt
swapon "${DEVICE}2"
mount --mkdir "${DEVICE}1" /mnt/boot/efi

# --- Pacstrap -----------------------------------------------------------------
echo "==> Installing base system"
pacstrap -K /mnt \
  base linux linux-firmware intel-ucode \
  networkmanager grub efibootmgr \
  hyprland kitty waybar wofi \
  pipewire pipewire-pulse wireplumber \
  mesa intel-media-driver \
  sudo nano git base-devel

# --- fstab --------------------------------------------------------------------
genfstab -U /mnt >> /mnt/etc/fstab

# --- Copy chroot script -------------------------------------------------------
cp "$(dirname "$0")/chroot-setup.sh" /mnt/root/
chmod +x /mnt/root/chroot-setup.sh

echo ""
echo "==> Base install done. Entering chroot..."
arch-chroot /mnt /root/chroot-setup.sh "${HOSTNAME}" "${USERNAME}"

# --- Cleanup ------------------------------------------------------------------
echo "==> Unmounting"
umount -R /mnt

echo ""
echo "Done! Remove the USB and reboot."
