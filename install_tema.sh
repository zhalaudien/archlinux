#!/bin/bash

# Download tema
echo "📥 Mengunduh tema..."
git clone https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git Tokyonight
git clone https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git Everforest

# Fungsi untuk menginstal tema
install_theme() {
    local theme_dir=$1
    local theme_name=$2

    echo "🧰 Menginstal Tema ${theme_name}..."

    if [ -f "${theme_dir}/themes/install.sh" ]; then
        chmod +x "${theme_dir}/themes/install.sh"
        sudo bash "${theme_dir}/themes/install.sh"
    else
        echo "❌ File install.sh tidak ditemukan di ${theme_dir}/themes/"
        exit 1
    fi

    echo "🧰 Menginstal Icon ${theme_name}..."
    if [ -d "${theme_dir}/icons" ]; then
        sudo cp -r "${theme_dir}/icons/"* /usr/share/icons/
    else
        echo "❌ Direktori ikon tidak ditemukan di ${theme_dir}/icons/"
    fi
}

# 1. Install Tema Everforest
install_theme "Everforest" "Everforest"

# 2. Install Tema Tokyonight
install_theme "Tokyonight" "Tokyonight"

# 3. Memastikan GNOME Tweaks terpasang
if ! command -v gnome-tweaks &> /dev/null; then
    echo "🔧 Menginstal GNOME Tweaks..."
    pacman -S --noconfirm gnome-tweaks
fi

echo "🧰 Install extensions gnome shell..."
cp -r /config/extensions ~/.local/share/gnome-shell

# 4. Membersihkan cache tema GTK
echo "🧹 Membersihkan cache tema GTK..."
gtk-update-icon-cache -f /usr/share/icons/*

# 5. Menghapus direktori tema setelah instalasi
echo "🗑️ Menghapus direktori tema yang sudah diinstal..."
sudo rm -rf Everforest Tokyonight

echo "✅ Instalasi Tema & Icon Everforest dan Tokyonight selesai!"
