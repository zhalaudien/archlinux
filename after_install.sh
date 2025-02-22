#!/bin/bash

# 1. Update system
echo "🧰 Menginstal aplikasi pendukung..."
sudo pacman -Syu --noconfirm

# 2. Install software
echo "🧰 Menginstal aplikasi pendukung..."
sudo pacman -S --noconfirm firefox gnome-tweaks gnome-shell-extensions power-profiles-daemon gnome-browser-connector gtk-engine-murrine neofetch htop

# 3. Setup AUR dengan yay
if ! command -v yay &> /dev/null; then
    echo "🚀 Menginstal yay (AUR Helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    $SUDO_USER git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    $SUDO_USER makepkg -si --noconfirm
    cd ~
    sudo rm -rf /tmp/yay-bin
fi

# 9. Cek status sistem
echo "📊 Informasi Sistem:"
uname -r
