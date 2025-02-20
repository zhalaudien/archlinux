#!/bin/bash

# Cek apakah script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Jalankan script ini sebagai root: sudo ./install-terminal-themes.sh"
    exit 1
fi

# 1. Install Fish Shell (Arch Linux/Manjaro)
echo "🐟 Menginstal Fish Shell..."
pacman -S fish --noconfirm

# Ganti shell default ke Fish
echo "🔄 Mengganti shell default ke Fish..."
chsh -s /usr/bin/fish

# 2. Install Oh My Posh
echo "🎨 Menginstal Oh My Posh..."
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
chmod +x /usr/local/bin/oh-my-posh

# 3. Install GNOME Tweaks (jika belum terpasang)
echo "🛠️ Memeriksa GNOME Tweaks..."
if ! command -v gnome-tweaks &> /dev/null; then
    pamac -S gnome-tweaks --noconfirm
fi

# 4. Download dan Install Font (FiraCode Nerd Font)
echo "🔤 Mengunduh dan Menginstal FiraCode Nerd Font..."
mkdir -p $HOME/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip -O $HOME/Downloads/firacode.zip
unzip $HOME/Downloads/firacode.zip -d $HOME/.local/share/fonts
fc-cache -f -v

# 5. Install dan Atur Tema Oh My Posh
echo "🎨 Mengatur Tema Oh My Posh..."
mkdir -p ~/.poshthemes
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O ~/.poshthemes/themes.zip
unzip ~/.poshthemes/themes.zip -d ~/.poshthemes
chmod u+rw ~/.poshthemes/*.json
rm ~/.poshthemes/themes.zip

# Tambahkan ke config Fish Shell
echo 'oh-my-posh init fish --config ~/.poshthemes/poshthemes.json | source' >> ~/.config/fish/config.fish

# 6. Mengganti Warna Terminal ke Everforest
echo "🌲 Mengatur skema warna ke Everforest..."
bash -c "$(wget -qO- https://git.io/vQgMr)"
echo "Pilih skema warna: Ketik 69 untuk Everforest Dark Hard"

echo "✅ Instalasi selesai! Silakan logout dan login kembali untuk menerapkan perubahan."
