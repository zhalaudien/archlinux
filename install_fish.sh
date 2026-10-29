#!/bin/bash

# ==============================================================================
# Script Instalasi & Konfigurasi Fish Shell, Oh My Posh, & Font
# ==============================================================================

if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(whoami)}"
    USER_HOME="$HOME"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Install Fish Shell & Font
echo "🐟 Menginstal Fish Shell & FiraCode Nerd Font..."
sudo pacman -S --needed --noconfirm fish ttf-firacode-nerd
fc-cache -f

# Ganti shell default ke Fish untuk user target
echo "🔄 Mengganti shell default ke Fish untuk ${REAL_USER}..."
sudo chsh -s /usr/bin/fish "$REAL_USER"

# 2. Install Oh My Posh binary
echo "🎨 Menginstal Oh My Posh..."
sudo wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

# 3. Install dan Atur Tema Oh My Posh
echo "🎨 Mengunduh paket tema Oh My Posh..."
POSH_DIR="$USER_HOME/.poshthemes"
mkdir -p "$POSH_DIR"
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O "$POSH_DIR/themes.zip"
unzip -qo "$POSH_DIR/themes.zip" -d "$POSH_DIR"
rm -f "$POSH_DIR/themes.zip"
chmod -R u+rw "$POSH_DIR"
chown -R "$REAL_USER:$REAL_USER" "$POSH_DIR"

# 4. Salin config Fish Shell
FISH_DIR="$USER_HOME/.config/fish"
mkdir -p "$FISH_DIR"
if [ -f "$SCRIPT_DIR/config/config.fish" ]; then
    echo "📄 Menyalin config.fish ke ${FISH_DIR}..."
    cp "$SCRIPT_DIR/config/config.fish" "$FISH_DIR/config.fish"
    chown -R "$REAL_USER:$REAL_USER" "$FISH_DIR"
fi

echo "✅ Instalasi Fish Shell & Oh My Posh selesai! Silakan logout dan login kembali untuk menerapkan perubahan."
