#!/usr/bin/env bash
# Runs inside arch-chroot. Called automatically by install.sh.
set -euo pipefail

HOSTNAME="${1:?}"
USERNAME="${2:?}"

# --- Time ---------------------------------------------------------------------
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# --- Locale -------------------------------------------------------------------
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# --- Hostname -----------------------------------------------------------------
echo "${HOSTNAME}" > /etc/hostname

# --- Root password ------------------------------------------------------------
echo "==> Set root password:"
passwd

# --- User ---------------------------------------------------------------------
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "==> Set password for ${USERNAME}:"
passwd "${USERNAME}"

# Enable sudo for wheel
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# --- GRUB ---------------------------------------------------------------------
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# --- Services -----------------------------------------------------------------
systemctl enable NetworkManager

echo "==> Chroot setup complete."
