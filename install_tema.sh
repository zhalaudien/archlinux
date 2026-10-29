#!/bin/bash

# ==============================================================================
# Script Instalasi Tema GTK, Ikon & GNOME Shell Extensions
# ==============================================================================

if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(whoami)}"
    USER_HOME="$HOME"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Install dependensi ikon & GNOME tools
echo "📥 Menginstal paket gnome-browser-connector, gnome-tweaks, dan papirus-icon-theme..."
sudo pacman -S --needed --noconfirm gnome-browser-connector gnome-tweaks papirus-icon-theme

# 2. Download dan install tema GTK
TEMP_DIR="/tmp/theme-install-standalone"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

echo "📥 Mengunduh repository tema Tokyonight & Everforest..."
git clone --depth 1 https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git "$TEMP_DIR/Tokyonight" 2>/dev/null || true
git clone --depth 1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git "$TEMP_DIR/Everforest" 2>/dev/null || true

install_theme() {
    local theme_path=$1
    local theme_name=$2

    echo "🧰 Menginstal Tema ${theme_name}..."
    if [ -f "${theme_path}/themes/install.sh" ]; then
        chmod +x "${theme_path}/themes/install.sh"
        sudo bash "${theme_path}/themes/install.sh"
    fi

    echo "🧰 Menginstal Icon ${theme_name}..."
    if [ -d "${theme_path}/icons" ]; then
        sudo cp -r "${theme_path}/icons/"* /usr/share/icons/ 2>/dev/null || true
    fi
}

install_theme "$TEMP_DIR/Everforest" "Everforest"
install_theme "$TEMP_DIR/Tokyonight" "Tokyonight"
rm -rf "$TEMP_DIR"

# 3. Install GNOME Shell Extensions
EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"
if [ -d "$SCRIPT_DIR/config/extensions" ]; then
    echo "🧰 Memasang GNOME Shell Extensions ke ${EXT_DIR}..."
    cp -r "$SCRIPT_DIR/config/extensions/"* "$EXT_DIR/"
    sudo chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/gnome-shell"
fi

# 4. Membersihkan dan memperbarui cache tema & icon GTK
echo "🧹 Memperbarui cache icon GTK..."
for theme_path in /usr/share/icons/*; do
    if [ -f "$theme_path/index.theme" ]; then
        sudo gtk-update-icon-cache -f -q "$theme_path" 2>/dev/null || true
    fi
done

echo "✅ Instalasi Tema & Icon Everforest dan Tokyonight selesai!"
