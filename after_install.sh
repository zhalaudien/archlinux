#!/bin/bash

# ==============================================================================
# Script Otomatisasi Pasca Instalasi Arch Linux (All-in-One Master Script)
# ==============================================================================
# Skrip ini menggabungkan seluruh tahapan setup untuk sistem baru:
#   1. Update sistem & instalasi paket pendukung dasar
#   2. Instalasi font lengkap (Noto Fonts & FiraCode Nerd Font)
#   3. Konfigurasi AUR Helper (yay-bin)
#   4. Fish Shell, Oh My Posh & Konfigurasi tema Fish
#   5. Tema GTK (Everforest, Tokyonight), Ikon Papirus & GNOME Shell Extensions
#   6. Fullstack Web Dev (PHP, Apache, MariaDB, phpMyAdmin, Composer)
#   7. Frontend & NPM Ecosystem (Node.js, NPM, Yarn, PNPM, base-devel, prefix fix)
#   8. Restart dan verifikasi status seluruh layanan
# ==============================================================================

set -eo pipefail

# Warna output terminal
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
RED="\e[1;31m"
CYAN="\e[1;36m"
BOLD="\e[1m"
RESET="\e[0m"

# ------------------------------------------------------------------------------
# 0. Pengecekan Izin Root & Deteksi User Asli
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Script ini harus dijalankan dengan hak akses root / sudo:${RESET}"
    echo -e "   ${BOLD}sudo ./after_install.sh${RESET}"
    exit 1
fi

# Dapatkan user asli non-root yang memanggil sudo
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(whoami)}"
    USER_HOME="$HOME"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}=====================================================${RESET}"
echo -e "${BOLD}   🚀 ARCH LINUX POST-INSTALLATION SETUP (ALL-IN-ONE)   ${RESET}"
echo -e "${CYAN}=====================================================${RESET}"
echo -e "User target : ${BOLD}${REAL_USER}${RESET}"
echo -e "Home user   : ${BOLD}${USER_HOME}${RESET}"
echo -e "Working dir : ${BOLD}${SCRIPT_DIR}${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}\n"

# ------------------------------------------------------------------------------
# 1. Update Sistem & Instalasi Paket Pendukung Dasar
# ------------------------------------------------------------------------------
echo -e "${BLUE}🔄 [1/7] Memperbarui sistem & menginstal aplikasi pendukung dasar...${RESET}"
pacman -Syu --noconfirm

PACKAGES_BASE=(
    firefox
    gnome-tweaks
    gnome-shell-extensions
    power-profiles-daemon
    gnome-browser-connector
    gtk-engine-murrine
    fastfetch
    htop
    git
    curl
    wget
    unzip
    tar
    base-devel
)

echo -e "${GREEN}📦 Menginstal paket dasar: ${PACKAGES_BASE[*]}...${RESET}"
pacman -S --needed --noconfirm "${PACKAGES_BASE[@]}"

# Aktifkan Power Profiles Daemon jika tersedia
if systemctl list-unit-files | grep -q "power-profiles-daemon.service"; then
    echo -e "${GREEN}⚡ Mengaktifkan power-profiles-daemon...${RESET}"
    systemctl enable --now power-profiles-daemon.service
fi

# ------------------------------------------------------------------------------
# 2. Instalasi Font Lengkap
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🔤 [2/7] Menginstal kumpulan font (Noto Fonts & FiraCode Nerd Font)...${RESET}"
pacman -S --needed --noconfirm \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    noto-fonts-extra \
    ttf-firacode-nerd

fc-cache -f

# ------------------------------------------------------------------------------
# 3. Setup AUR Helper (yay-bin)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🚀 [3/7] Memeriksa & mengonfigurasi AUR Helper (yay)...${RESET}"
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}⚙️  yay belum terpasang. Membangun yay-bin dari AUR...${RESET}"
    YAY_TMP="/tmp/yay-bin"
    rm -rf "$YAY_TMP"
    sudo -u "$REAL_USER" git clone https://aur.archlinux.org/yay-bin.git "$YAY_TMP"
    cd "$YAY_TMP"
    sudo -u "$REAL_USER" makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$YAY_TMP"
    echo -e "${GREEN}✅ yay berhasil terpasang!${RESET}"
else
    echo -e "${GREEN}✅ yay sudah terpasang.${RESET}"
fi

# ------------------------------------------------------------------------------
# 4. Fish Shell, Oh My Posh & Konfigurasi Terminal
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🐟 [4/7] Menginstal dan mengonfigurasi Fish Shell & Oh My Posh...${RESET}"
pacman -S --needed --noconfirm fish

# Ubah shell default untuk user target ke Fish
CURRENT_SHELL="$(getent passwd "$REAL_USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "/usr/bin/fish" ]; then
    echo -e "${GREEN}🔄 Mengubah default shell untuk user '${REAL_USER}' ke /usr/bin/fish...${RESET}"
    chsh -s /usr/bin/fish "$REAL_USER"
fi

# Unduh dan pasang binary Oh My Posh
echo -e "${GREEN}🎨 Mengunduh binary Oh My Posh...${RESET}"
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
chmod +x /usr/local/bin/oh-my-posh

# Unduh dan pasang kumpulan tema Oh My Posh ke folder home user
POSH_DIR="$USER_HOME/.poshthemes"
mkdir -p "$POSH_DIR"
echo -e "${GREEN}🎨 Mengunduh paket tema Oh My Posh...${RESET}"
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O "$POSH_DIR/themes.zip"
unzip -qo "$POSH_DIR/themes.zip" -d "$POSH_DIR"
rm -f "$POSH_DIR/themes.zip"
chmod -R u+rw "$POSH_DIR"
chown -R "$REAL_USER:$REAL_USER" "$POSH_DIR"

# Pasang konfigurasi Fish
FISH_CONFIG_DIR="$USER_HOME/.config/fish"
mkdir -p "$FISH_CONFIG_DIR"
if [ -f "$SCRIPT_DIR/config/config.fish" ]; then
    echo -e "${GREEN}📄 Menyalin konfigurasi config.fish ke ${FISH_CONFIG_DIR}...${RESET}"
    cp "$SCRIPT_DIR/config/config.fish" "$FISH_CONFIG_DIR/config.fish"
    chown -R "$REAL_USER:$REAL_USER" "$FISH_CONFIG_DIR"
fi

# ------------------------------------------------------------------------------
# 5. Tema GTK, Ikon & GNOME Shell Extensions
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🎨 [5/7] Menginstal Tema GTK, Ikon & GNOME Extensions...${RESET}"
pacman -S --needed --noconfirm papirus-icon-theme

TEMP_THEME_DIR="/tmp/theme-install-all"
rm -rf "$TEMP_THEME_DIR"
mkdir -p "$TEMP_THEME_DIR"

echo -e "${GREEN}📥 Mengunduh tema Tokyonight & Everforest...${RESET}"
git clone --depth 1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git "$TEMP_THEME_DIR/Everforest" 2>/dev/null || true
git clone --depth 1 https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git "$TEMP_THEME_DIR/Tokyonight" 2>/dev/null || true

for theme in Everforest Tokyonight; do
    if [ -f "$TEMP_THEME_DIR/$theme/themes/install.sh" ]; then
        echo -e "${GREEN}🧰 Menjalankan installer tema ${theme}...${RESET}"
        chmod +x "$TEMP_THEME_DIR/$theme/themes/install.sh"
        bash "$TEMP_THEME_DIR/$theme/themes/install.sh" || true
    fi
    if [ -d "$TEMP_THEME_DIR/$theme/icons" ]; then
        echo -e "${GREEN}🧰 Memasang icon set ${theme}...${RESET}"
        cp -r "$TEMP_THEME_DIR/$theme/icons/"* /usr/share/icons/ 2>/dev/null || true
    fi
done
rm -rf "$TEMP_THEME_DIR"

# Pasang GNOME Shell Extensions dari direktori repo ke home user
EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"
if [ -d "$SCRIPT_DIR/config/extensions" ]; then
    echo -e "${GREEN}🧩 Memasang GNOME Shell Extensions ke ${EXT_DIR}...${RESET}"
    cp -r "$SCRIPT_DIR/config/extensions/"* "$EXT_DIR/"
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/gnome-shell"
fi

# Perbarui cache icon di /usr/share/icons
echo -e "${GREEN}🧹 Memperbarui icon cache GTK...${RESET}"
for theme_path in /usr/share/icons/*; do
    if [ -f "$theme_path/index.theme" ]; then
        gtk-update-icon-cache -f -q "$theme_path" 2>/dev/null || true
    fi
done

# ------------------------------------------------------------------------------
# 6. Web & Backend Development (Apache, MariaDB, PHP, phpMyAdmin, Composer)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🌐 [6/7] Menginstal Apache, MariaDB, PHP, phpMyAdmin, dan Composer...${RESET}"
pacman -S --needed --noconfirm \
    apache \
    mariadb mariadb-clients \
    php php-fpm php-gd php-intl unzip php-cgi php-pgsql php-apache \
    phpmyadmin

# Inisialisasi Database MariaDB
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo -e "${GREEN}🗄️ Menginisialisasi direktori data MariaDB...${RESET}"
    mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi
systemctl enable --now mariadb.service

# Konfigurasi Apache & PHP-FPM
echo -e "${GREEN}🔧 Mengatur integrasi Apache dengan PHP-FPM...${RESET}"
mkdir -p /etc/httpd/conf/extra /srv/http
cat <<'EOF' > /etc/httpd/conf/extra/php-fpm.conf
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/php-fpm.sock|fcgi://localhost"
</FilesMatch>
EOF

# File info.php
echo "<?php phpinfo(); ?>" > /srv/http/info.php

# Salin konfigurasi kustom dari folder repo jika tersedia
[ -f "$SCRIPT_DIR/config/httpd.conf" ] && cp "$SCRIPT_DIR/config/httpd.conf" /etc/httpd/conf/httpd.conf
[ -f "$SCRIPT_DIR/config/phpmyadmin.conf" ] && cp "$SCRIPT_DIR/config/phpmyadmin.conf" /etc/httpd/conf/extra/phpmyadmin.conf
[ -f "$SCRIPT_DIR/config/php.ini" ] && cp "$SCRIPT_DIR/config/php.ini" /etc/php/php.ini

# Pastikan ekstensi mysqli aktif di php.ini
sed -i 's/^;extension=mysqli/extension=mysqli/' /etc/php/php.ini

# Konfigurasi phpMyAdmin symlink dan hak akses
rm -rf /srv/http/phpmyadmin
ln -s /usr/share/webapps/phpMyAdmin /srv/http/phpmyadmin
chown -R http:http /usr/share/webapps/phpMyAdmin /srv/http
chmod -R 755 /usr/share/webapps/phpMyAdmin /srv/http

systemctl enable --now php-fpm.service
systemctl enable --now httpd.service

# Instalasi Composer
if ! command -v composer &> /dev/null; then
    echo -e "${GREEN}📦 Menginstal Composer secara global...${RESET}"
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"

    if [ "$EXPECTED_SIGNATURE" = "$ACTUAL_SIGNATURE" ]; then
        php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
        rm -f /tmp/composer-setup.php
        echo -e "${GREEN}✅ Composer berhasil diinstal!${RESET}"
    else
        echo -e "${RED}❌ Checksum verifikasi Composer tidak cocok!${RESET}"
        rm -f /tmp/composer-setup.php
    fi
else
    echo -e "${GREEN}✅ Composer sudah terpasang.${RESET}"
fi

# ------------------------------------------------------------------------------
# 7. Frontend & NPM Ecosystem (Node.js, NPM, Yarn, PNPM & User Prefix)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🟢 [7/7] Menginstal Node.js, NPM, Yarn, PNPM & Konfigurasi Development...${RESET}"
pacman -S --needed --noconfirm nodejs npm yarn pnpm

# Konfigurasi npm global prefix untuk user biasa (mencegah error permission EACCES)
if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
    NPM_DIR="$USER_HOME/.npm-global"
    echo -e "${GREEN}🔧 Mengatur direktori prefix npm global di ${NPM_DIR}...${RESET}"
    mkdir -p "$NPM_DIR/bin" "$NPM_DIR/lib"
    chown -R "$REAL_USER:$REAL_USER" "$NPM_DIR"
    sudo -u "$REAL_USER" npm config set prefix "$NPM_DIR"

    # Tambahkan ke konfigurasi shell user (Bash, Zsh, Fish)
    [ -f "$USER_HOME/.bashrc" ] && ! grep -q "npm-global/bin" "$USER_HOME/.bashrc" && \
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$USER_HOME/.bashrc"

    [ -f "$USER_HOME/.zshrc" ] && ! grep -q "npm-global/bin" "$USER_HOME/.zshrc" && \
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$USER_HOME/.zshrc"

    if [ -f "$FISH_CONFIG_DIR/config.fish" ] && ! grep -q "npm-global/bin" "$FISH_CONFIG_DIR/config.fish"; then
        echo 'fish_add_path $HOME/.npm-global/bin' >> "$FISH_CONFIG_DIR/config.fish"
    fi
fi

# ------------------------------------------------------------------------------
# Restart Layanan Terkait
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🔄 Memulai ulang layanan web server & database...${RESET}"
systemctl restart mariadb.service
systemctl restart php-fpm.service
systemctl restart httpd.service

# ------------------------------------------------------------------------------
# Ringkasan Akhir
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}=====================================================${RESET}"
echo -e "${BOLD}🎉 SEMUA TAHAPAN INSTALASI & SETUP SELESAI!${RESET}"
echo -e "${CYAN}=====================================================${RESET}"
echo -e "Kernel Sistem : ${BOLD}$(uname -r)${RESET}"
echo -e "Default Shell : ${BOLD}$(getent passwd "$REAL_USER" | cut -d: -f7)${RESET}"
echo -e "Web Server    : Apache httpd (http://localhost/)"
echo -e "Database      : MariaDB (Service: active)"
echo -e "PHP Version   : $(php -v | head -n 1 | awk '{print $2}')"
echo -e "phpMyAdmin    : ${GREEN}http://localhost/phpmyadmin${RESET}"
echo -e "Web Root      : /srv/http/"
echo -e "Composer      : $(composer --version 2>/dev/null | cut -d' ' -f3 || echo 'Terpasang')"
echo -e "Node.js       : $(node -v 2>/dev/null || echo 'Terpasang')"
echo -e "NPM           : v$(npm -v 2>/dev/null || echo 'Terpasang')"
echo -e "Yarn          : v$(yarn -v 2>/dev/null || echo 'Terpasang')"
echo -e "PNPM          : v$(pnpm -v 2>/dev/null || echo 'Terpasang')"
echo -e "${CYAN}=====================================================${RESET}"
echo -e "${YELLOW}💡 Catatan: Silakan logout dan login kembali agar perubahan shell dan tema aktif sepenuhnya.${RESET}\n"
