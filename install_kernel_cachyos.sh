#!/bin/bash

set -e

#=========================================
# Install CachyOS Kernel (Automatic)
#=========================================

if [[ $EUID -ne 0 ]]; then
    echo "Jalankan sebagai root"
    echo "sudo ./install-cachyos-kernel.sh"
    exit 1
fi

clear

echo "==========================================="
echo "     CachyOS Kernel Installer"
echo "==========================================="

echo
echo "==> Install dependency..."

pacman -Sy --needed --noconfirm \
    curl \
    wget \
    tar \
    gnupg \
    reflector

echo
echo "==> Download CachyOS Repository..."

rm -rf /tmp/cachyos-repo*
mkdir -p /tmp/cachyos-install

curl -fsSL \
https://mirror.cachyos.org/cachyos-repo.tar.xz \
-o /tmp/cachyos-install/cachyos-repo.tar.xz

cd /tmp/cachyos-install

tar -xf cachyos-repo.tar.xz

cd cachyos-repo

chmod +x cachyos-repo.sh

echo
echo "==> Install Repository..."

yes | ./cachyos-repo.sh

echo
echo "==> Refresh Database..."

pacman -Syy --noconfirm

echo
echo "==> Install CachyOS Kernel..."

pacman -S --needed --noconfirm \
    linux-cachyos \
    linux-cachyos-headers

echo
echo "==> Generate Initramfs..."

mkinitcpio -P

echo
echo "==> Update Bootloader..."

if command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg
fi

if [[ -d /boot/loader ]]; then
    bootctl update
fi

echo
echo "==> Cleanup..."

rm -rf /tmp/cachyos-install

echo
echo "==========================================="
echo " Install Success"
echo "==========================================="
echo
echo "Kernel : linux-cachyos"
echo
echo "Silakan reboot:"
echo
echo "sudo reboot"
echo
echo "Setelah boot:"
echo
echo "uname -r"
