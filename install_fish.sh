#!/bin/bash

# 1. Install Fish Shell (Arch Linux/Manjaro)
echo "🐟 Menginstal Fish Shell..."
sudo pacman -S fish --noconfirm

# Ganti shell default ke Fish
echo "🔄 Mengganti shell default ke Fish..."
chsh -s /usr/bin/fish

# 2. Install Oh My Posh
echo "🎨 Menginstal Oh My Posh..."
sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

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
cp config/config.fish ~/.config/fish/

# 6. Mengganti Warna Terminal ke Everforest
echo "🌲 Mengatur skema warna ke Everforest..."
echo "Pilih skema warna: Ketik 124 untuk Everforest Dark Hard"
bash -c "$(wget -qO- https://git.io/vQgMr)"


echo "✅ Instalasi selesai! Silakan logout dan login kembali untuk menerapkan perubahan."
