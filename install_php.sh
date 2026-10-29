#!/bin/bash

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Jalankan script ini sebagai root: sudo ./install_php.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Memulai instalasi MariaDB, PHP, phpMyAdmin, Composer, Apache, dan Node.js/NPM Ecosystem..."

# 1. Install Apache Web Server
echo "🌐 Menginstal Apache Web Server (httpd)..."
pacman -S --noconfirm apache
echo "<?php phpinfo(); ?>" | sudo tee /srv/http/info.php


# Jalankan dan aktifkan Apache
echo "🔄 Mengaktifkan dan menjalankan Apache..."
systemctl enable --now httpd.service

# 2. Install MariaDB Server
echo "🗄️ Menginstal MariaDB Server..."
pacman -S --noconfirm mariadb mariadb-clients

# Inisialisasi database jika belum diinisialisasi
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "🛠️ Inisialisasi database MariaDB..."
    mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi

# Jalankan dan aktifkan MariaDB
echo "🔄 Mengaktifkan dan memulai MariaDB..."
systemctl enable --now mariadb.service

# Konfigurasi Keamanan MariaDB
echo "🔒 Menjalankan mysql_secure_installation..."
mysql_secure_installation

echo "✅ MariaDB telah diinstal dan dikonfigurasi."

# 3. Install PHP dan Ekstensi Penting
echo "🐘 Menginstal PHP dan ekstensi yang diperlukan..."
pacman -S --noconfirm php php-fpm php-gd php-intl unzip php-cgi php-pgsql php-apache

# Konfigurasi PHP-FPM jika belum diatur
if [ ! -f "/etc/php/php.ini" ]; then
    echo "📄 Membuat salinan konfigurasi php.ini..."
    cp /etc/php/php.ini.default /etc/php/php.ini
fi

# Konfigurasi Apache untuk menggunakan PHP-FPM
echo "🔧 Mengatur Apache untuk menjalankan PHP-FPM..."
cat <<EOF > /etc/httpd/conf/extra/php-fpm.conf
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/php-fpm.sock|fcgi://localhost"
</FilesMatch>
EOF

# Tambahkan konfigurasi PHP-FPM di httpd.conf jika belum ada
[ -f "$SCRIPT_DIR/config/httpd.conf" ] && cp "$SCRIPT_DIR/config/httpd.conf" /etc/httpd/conf/httpd.conf
[ -f "$SCRIPT_DIR/config/phpmyadmin.conf" ] && cp "$SCRIPT_DIR/config/phpmyadmin.conf" /etc/httpd/conf/extra/
[ -f "$SCRIPT_DIR/config/php.ini" ] && cp "$SCRIPT_DIR/config/php.ini" /etc/php/php.ini

# Jalankan dan aktifkan PHP-FPM
echo "🔄 Mengaktifkan dan memulai PHP-FPM..."
systemctl enable --now php-fpm.service

# 4. Install phpMyAdmin
echo "📊 Menginstal phpMyAdmin..."
pacman -S --noconfirm phpmyadmin

# Konfigurasi phpMyAdmin
echo "🔧 Konfigurasi phpMyAdmin..."

# Tambahkan konfigurasi di php.ini jika belum ada
if ! grep -q "extension=mysqli" /etc/php/php.ini; then
    echo "🛠️ Menambahkan ekstensi mysqli di php.ini..."
    sed -i 's/;extension=mysqli/extension=mysqli/' /etc/php/php.ini
fi

sudo rm -rf /srv/http/phpmyadmin 

# Buat symlink untuk phpMyAdmin
if [ ! -d "/srv/http/phpmyadmin" ]; then
    sudo ln -s /usr/share/webapps/phpMyAdmin /srv/http/phpmyadmin
fi

sudo chown -R http:http /usr/share/webapps/phpMyAdmin
sudo chmod -R 755 /usr/share/webapps/phpMyAdmin

echo "✅ phpMyAdmin dapat diakses di: http://localhost/phpmyadmin"

# 5. Install Composer
echo "📦 Menginstal Composer..."
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

# Verifikasi checksum untuk keamanan
HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); exit(1); } echo PHP_EOL;"

# Jalankan installer
php composer-setup.php
php -r "unlink('composer-setup.php');"

# Pindahkan Composer ke lokasi global
mv composer.phar /usr/local/bin/composer

# Verifikasi instalasi Composer
if command -v composer &> /dev/null; then
    echo "✅ Composer berhasil diinstal. Versi:"
    composer --version
else
    echo "❌ Gagal menginstal Composer!"
    exit 1
fi

# 6. Install Node.js, NPM, dan Penunjang Development Berbasis NPM
echo "🟢 Menginstal Node.js, NPM, dan alat penunjang development (yarn, pnpm, base-devel)..."
pacman -S --needed --noconfirm nodejs npm yarn pnpm base-devel

# Konfigurasi npm global directory agar user biasa bisa install paket global tanpa sudo (mencegah error permission EACCES)
TARGET_USER="${SUDO_USER:-$USER}"
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    if [ -d "$USER_HOME" ]; then
        echo "🔧 Mengatur direktori prefix npm global untuk user: $TARGET_USER..."
        NPM_DIR="$USER_HOME/.npm-global"
        mkdir -p "$NPM_DIR/bin" "$NPM_DIR/lib"
        chown -R "$TARGET_USER:$TARGET_USER" "$NPM_DIR"
        
        # Atur prefix npm untuk target user
        sudo -u "$TARGET_USER" npm config set prefix "$NPM_DIR"

        # Tambahkan ke ~/.bashrc jika belum ada
        if [ -f "$USER_HOME/.bashrc" ] && ! grep -q "npm-global/bin" "$USER_HOME/.bashrc"; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$USER_HOME/.bashrc"
        fi

        # Tambahkan ke ~/.zshrc jika ada
        if [ -f "$USER_HOME/.zshrc" ] && ! grep -q "npm-global/bin" "$USER_HOME/.zshrc"; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$USER_HOME/.zshrc"
        fi

        # Tambahkan ke Fish Shell config jika ada
        FISH_CONFIG="$USER_HOME/.config/fish/config.fish"
        if [ -f "$FISH_CONFIG" ] && ! grep -q "npm-global/bin" "$FISH_CONFIG"; then
            echo 'fish_add_path $HOME/.npm-global/bin' >> "$FISH_CONFIG"
        fi
    fi
fi

# Verifikasi instalasi ekosistem Node.js & NPM
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    echo "✅ Node.js terinstal: $(node -v)"
    echo "✅ NPM terinstal: v$(npm -v)"
    command -v yarn &> /dev/null && echo "✅ Yarn terinstal: v$(yarn -v)"
    command -v pnpm &> /dev/null && echo "✅ PNPM terinstal: v$(pnpm -v)"
else
    echo "❌ Gagal memverifikasi instalasi Node.js / NPM!"
    exit 1
fi

# 7. Restart dan Cek Status Semua Service
echo "🔄 Merestart layanan terkait..."
systemctl restart mariadb.service
systemctl restart php-fpm.service
systemctl restart httpd.service

# Cek status layanan
systemctl status mariadb.service --no-pager
systemctl status php-fpm.service --no-pager
systemctl status httpd.service --no-pager

echo "🎉 Instalasi selesai!"
echo "✅ Akses phpMyAdmin di: http://localhost/phpmyadmin"
echo "✅ Web root: /srv/http/"
echo "✅ PHP: $(php -v | head -n 1 | awk '{print $2}')"
echo "✅ Composer: $(composer --version | cut -d' ' -f3)"
echo "✅ Node.js: $(node -v)"
echo "✅ NPM: v$(npm -v)"
