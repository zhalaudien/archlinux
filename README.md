# Arch Linux Post-Installation Toolkit

Koleksi skrip otomatisasi konfigurasi dan setup pasca-instalasi Arch Linux dengan Desktop GNOME. Dirancang khusus untuk workflow developer: Fish Shell + Oh My Posh, tema modern GTK & ikon, ekstensi GNOME Shell, serta lingkungan Fullstack Web Development (PHP, Apache, MariaDB, Composer, Node.js, NPM, Yarn, PNPM).

---

## 🚀 Setup Cepat (All-in-One)

Cukup jalankan satu skrip `after_install.sh` untuk menginstal seluruh ekosistem sekaligus di instalasi baru:

```bash
# 1. Pastikan git terpasang
sudo pacman -S --needed git

# 2. Clone repositori ke home
cd ~
git clone https://github.com/zhalaudien/archlinux.git
cd archlinux

# 3. Jalankan script utama (All-in-One)
sudo ./after_install.sh
```

### Yang diinstal & dikonfigurasi oleh `after_install.sh`:
1. **Sistem & Aplikasi Dasar:** Update sistem (`pacman -Syu`), Firefox, GNOME Tweaks, GNOME Extensions, Fastfetch, Htop, Power Profiles Daemon, Base-devel, Git, Wget, Curl.
2. **Font:** Noto Fonts lengkap & FiraCode Nerd Font.
3. **AUR Helper:** Membangun & mengonfigurasi `yay-bin` secara otomatis.
4. **Shell & Terminal:** Fish Shell (dijadikan default shell), Oh My Posh prompt engine, kumpulan tema Oh My Posh, serta konfigurasi `config.fish`.
5. **Tema & GNOME Shell:** Tema GTK Everforest & Tokyonight, Papirus Icon Theme, dan instalasi ekstensi GNOME Shell dari `config/extensions/`.
6. **Backend Development:** Apache (httpd), MariaDB Server, PHP & ekstensi lengkap, phpMyAdmin (`http://localhost/phpmyadmin`), dan Composer global.
7. **Frontend / NPM Ecosystem:** Node.js, NPM, Yarn, PNPM, serta konfigurasi prefix global (`~/.npm-global`) agar bebas dari error hak akses `EACCES` saat menginstal paket global.

---

## 🛠️ Menjalankan Skrip Parsial (Opsional)

Jika hanya ingin menginstal komponen tertentu secara terpisah:

- **Fish Shell & Oh My Posh:**
  ```bash
  ./install_fish.sh
  ```

- **Tema GTK & Ekstensi GNOME:**
  ```bash
  ./install_tema.sh
  ```

- **Stack Web Development (PHP, Apache, MariaDB, Node.js, NPM):**
  ```bash
  sudo ./install_php.sh
  ```

- **Flutter & Android SDK Development:**
  ```bash
  ./install_flutter.sh
  ```

---

## 🧹 Optimalisasi & Pembersihan Sistem

Gunakan skrip `optimize_system.sh` untuk membersihkan cache pacman, menghapus paket yatim (*orphaned packages*), memangkas systemd journal log, dan memeriksa kesehatan sistem:

```bash
# Mode interaktif (dengan konfirmasi di setiap langkah)
./optimize_system.sh

# Mode otomatis (langsung jalankan rekomendasi pembersihan)
./optimize_system.sh -y
```

---

## 🔄 Pembaruan Skrip

Untuk menarik perbaikan terbaru dari repositori:

```bash
cd ~/archlinux
git pull
```
