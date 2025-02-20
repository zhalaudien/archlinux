#!/bin/bash

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Jalankan script ini sebagai root: sudo ./install_php.sh"
    exit 1
fi

echo "🚀 Memulai instalasi MariaDB, PHP, phpMyAdmin, dan Composer..."

# 1. Install MariaDB Server
echo "🗄️ Menginstal MariaDB Server..."
pacman -S update && pacman -S --noconfirm mariadb-server

# Jalankan dan aktifkan MariaDB
systemctl start mariadb
systemctl enable mariadb

# Konfigurasi Keamanan MariaDB
echo "🔒 Mengatur keamanan MariaDB..."
mysql_secure_installation <<EOF

y
y
passwordbaru
passwordbaru
y
y
y
y
EOF

echo "✅ MariaDB telah diinstal dan dikonfigurasi."

# 2. Install PHP dan Ekstensi Penting
echo "🐘 Menginstal PHP dan ekstensi yang diperlukan..."
pacman -S --noconfirm php php-fpm php-gd php-xml php-mbstring php-curl php-intl php-zip unzip

# 3. Install phpMyAdmin
echo "📊 Menginstal phpMyAdmin..."
DEBIAN_FRONTEND=noninteractive pacman -S --noconfirm phpmyadmin

# Konfigurasi phpMyAdmin
echo "🔧 Konfigurasi phpMyAdmin..."
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

echo "✅ phpMyAdmin dapat diakses di: http://localhost/phpmyadmin"

# 4. Install Composer
echo "📦 Menginstal Composer..."
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

HASH="$(wget -q -O - https://composer.github.io/installer.sig)"

php -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); exit(1); } echo PHP_EOL;"

php composer-setup.php
php -r "unlink('composer-setup.php');"

# Pindahkan Composer ke lokasi global
mv composer.phar /usr/local/bin/composer

echo "✅ Composer berhasil diinstal. Cek dengan menjalankan: composer --version"

# Restart service untuk menerapkan perubahan
echo "🔄 Merestart layanan terkait..."
systemctl restart mariadb
systemctl restart php7.4-fpm || systemctl restart php8.2-fpm

echo "🎉 Instalasi selesai! Akses phpMyAdmin di: http://localhost/phpmyadmin"
