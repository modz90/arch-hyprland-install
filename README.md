# Arch Linux + Hyprland Install Guide

Personal install guide for Arch Linux with Hyprland on a Seagate 466 GB external drive.

**Hardware:**
- CPU: Intel Celeron N4020
- GPU: Intel UHD Graphics 600 (integrated)
- RAM: ~4 GB
- Boot: UEFI, Secure Boot OFF
- Target drive: ~466 GB (confirm with `lsblk` — do NOT wipe the Windows drive)

---

## Step 1 — Boot into Arch live environment

1. Flash `archlinux-*.iso` to USB with Rufus (GPT, UEFI non-CSM, DD mode)
2. Reboot → enter BIOS (F2 / F12 / Del / Esc)
3. Boot from the USB

---

## Step 2 — Connect to Wi-Fi

```bash
iwctl
device list                        # find device name e.g. wlan0
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "YourSSID"   # enter password when prompted
exit
ping archlinux.org                 # confirm connection
```

---

## Step 3 — Identify your drives

```bash
lsblk
```

You should see:
- A small drive (~58 GB) — this is the **Windows drive**, DO NOT touch it
- A ~466 GB drive — this is your **target install drive**

Take note of the device name, e.g. `/dev/sdb`. Replace `sdX` in all commands below with your drive letter.

---

## Step 4 — Partition the target drive

```bash
cfdisk /dev/sdX
```

In cfdisk:
1. Select `gpt` if prompted
2. Create 3 partitions:

| Partition | Size      | Type             | Mount point  |
|-----------|-----------|------------------|--------------|
| sdX1      | 512M      | EFI System       | /boot/efi    |
| sdX2      | 4G        | Linux swap       | swap         |
| sdX3      | remaining | Linux filesystem | /            |

3. **Write** then **Quit**

---

## Step 5 — Format and mount

```bash
mkfs.fat -F32 /dev/sdX1
mkswap /dev/sdX2
mkfs.ext4 /dev/sdX3

mount /dev/sdX3 /mnt
swapon /dev/sdX2
mount --mkdir /dev/sdX1 /mnt/boot/efi
```

---

## Step 6 — Install base system

```bash
pacstrap -K /mnt base linux linux-firmware intel-ucode \
  networkmanager grub efibootmgr \
  hyprland kitty waybar wofi \
  pipewire pipewire-pulse wireplumber \
  mesa intel-media-driver \
  sudo nano git base-devel
```

This installs:
- Kernel + Intel microcode + firmware
- NetworkManager (Wi-Fi after reboot)
- GRUB bootloader
- Hyprland + kitty (terminal) + waybar (status bar) + wofi (app launcher)
- Pipewire (audio)
- Intel GPU drivers (mesa + intel-media-driver)

---

## Step 7 — Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

---

## Step 8 — Chroot and configure

```bash
arch-chroot /mnt
```

### Timezone (change Region/City to yours e.g. America/New_York)
```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
```

### Locale
```bash
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### Hostname (replace `myhostname` with whatever you want)
```bash
echo "myhostname" > /etc/hostname
```

### Root password
```bash
passwd
```

### Create your user (replace `youruser` with your username)
```bash
useradd -m -G wheel -s /bin/bash youruser
passwd youruser
```

### Enable sudo for wheel group
```bash
EDITOR=nano visudo
```
Find and uncomment this line (remove the `#`):
```
%wheel ALL=(ALL:ALL) ALL
```
Save: `Ctrl+O` → Enter → `Ctrl+X`

---

## Step 9 — Install GRUB

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Step 10 — Enable services and reboot

```bash
systemctl enable NetworkManager
exit
umount -R /mnt
reboot
```

Remove the USB drive when the machine restarts.

---

## Step 11 — First boot

Login as your user, then:

### Connect to Wi-Fi
```bash
nmtui
```

### Launch Hyprland
```bash
Hyprland
```

---

## Step 12 — Hyprland config (after first launch)

Config file location:
```
~/.config/hypr/hyprland.conf
```

Default keybindings:
- `Super + Q` — open terminal (kitty)
- `Super + R` — open app launcher (wofi)
- `Super + M` — exit Hyprland
- `Super + 1-9` — switch workspaces
- `Super + Shift + 1-9` — move window to workspace

---

## Useful commands after install

```bash
# Update system
sudo pacman -Syu

# Install an AUR helper (yay)
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si

# Check GPU rendering
glxinfo | grep "OpenGL renderer"
```

---

## Troubleshooting

**No internet after reboot:**
```bash
sudo systemctl start NetworkManager
nmtui
```

**Hyprland won't start (display error):**
```bash
# Make sure you're not running as root
# Check logs:
cat ~/.local/share/hyprland/hyprland.log
```

**Black screen on boot:**
- Re-enter BIOS and make sure it's booting from the GRUB entry on your 466 GB drive, not the USB
