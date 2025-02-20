#!/bin/bash

# 1. Update system
echo "🧰 Menginstal aplikasi pendukung..."
pacman -Syu --noconfirm

# 2. Install software
echo "🧰 Menginstal aplikasi pendukung..."
pacman -S --noconfirm firefox gnome-tweaks gnome-shell-extensions power-profiles-daemon gnome-browser-connector gtk-engine-murrine

# 3. Setup AUR dengan yay
if ! command -v yay &> /dev/null; then
    echo "🚀 Menginstal yay (AUR Helper)..."
    pacman -S --needed --noconfirm base-devel git
    sudo -u $SUDO_USER git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    sudo -u $SUDO_USER makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay-bin
fi

# 9. Cek status sistem
echo "📊 Informasi Sistem:"
uname -r
