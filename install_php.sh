#!/bin/bash

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Jalankan script ini sebagai root: sudo ./install_php.sh"
    exit 1
fi

echo "🚀 Memulai instalasi MariaDB, PHP, phpMyAdmin, dan Composer..."

# 1. Install MariaDB Server
echo "🗄️ Menginstal MariaDB Server..."
pacman -S --noconfirm mariadb mariadb-clients

# Inisialisasi database MariaDB jika belum diinisialisasi
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

# 2. Install PHP dan Ekstensi Penting
echo "🐘 Menginstal PHP dan ekstensi yang diperlukan..."
pacman -S --noconfirm apache2 php php-fpm php-gd php-intl unzip php-cgi php-pgsql php-apache

# Konfigurasi PHP-FPM jika belum diatur
if [ ! -f "/etc/php/php.ini" ]; then
    echo "📄 Membuat salinan konfigurasi php.ini..."
    cp /etc/php/php.ini.default /etc/php/php.ini
fi

# Jalankan dan aktifkan PHP-FPM
echo "🔄 Mengaktifkan dan memulai PHP-FPM..."
systemctl enable --now php-fpm.service

# 3. Install phpMyAdmin
echo "📊 Menginstal phpMyAdmin..."
pacman -S --noconfirm phpmyadmin

# Konfigurasi phpMyAdmin
echo "🔧 Konfigurasi phpMyAdmin..."

# Tambahkan konfigurasi di php.ini jika belum ada
if ! grep -q "extension=mysqli" /etc/php/php.ini; then
    echo "🛠️ Menambahkan ekstensi mysqli di php.ini..."
    sed -i 's/;extension=mysqli/extension=mysqli/' /etc/php/php.ini
fi

# Buat symlink untuk phpMyAdmin
if [ ! -d "/var/www/html/phpmyadmin" ]; then
    ln -s /usr/share/webapps/phpmyadmin /var/www/html/phpmyadmin
fi

echo "✅ phpMyAdmin dapat diakses di: http://localhost/phpmyadmin"

# 4. Install Composer
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

# 5. Restart service untuk menerapkan perubahan
echo "🔄 Merestart layanan terkait..."
systemctl restart mariadb.service
systemctl restart php-fpm.service

# Cek status layanan
systemctl status mariadb.service --no-pager
systemctl status php-fpm.service --no-pager

echo "🎉 Instalasi selesai! Akses phpMyAdmin di: http://localhost/phpmyadmin"
