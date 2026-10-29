#!/bin/bash

# ==============================================================================
# Script Optimalisasi & Pembersihan Sistem Arch Linux
# ==============================================================================
# Deskripsi : Skrip otomatis untuk membersihkan cache pacman, menghapus paket
#             yatim (orphaned packages), membersihkan cache AUR, journal log,
#             dan mengecek kesehatan sistem.
# ==============================================================================

# Warna untuk output terminal
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
RED="\e[1;31m"
CYAN="\e[1;36m"
BOLD="\e[1m"
RESET="\e[0m"

# Mode otomatis (jika diberi argumen -y atau --noconfirm)
AUTO_CONFIRM=false
if [[ "$1" == "-y" || "$1" == "--noconfirm" || "$1" == "--auto" ]]; then
    AUTO_CONFIRM=true
fi

# Fungsi konfirmasi pengguna
confirm() {
    local prompt_msg="$1"
    local default_val="$2" # Y atau N

    if [ "$AUTO_CONFIRM" = true ]; then
        return 0
    fi

    if [ "$default_val" = "Y" ]; then
        read -rp "$(echo -e "${YELLOW}${prompt_msg} [Y/n]: ${RESET}")" response
        response=${response:-Y}
        [[ "$response" =~ ^[Yy]$ ]] && return 0 || return 1
    else
        read -rp "$(echo -e "${YELLOW}${prompt_msg} [y/N]: ${RESET}")" response
        response=${response:-N}
        [[ "$response" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

echo -e "${CYAN}=====================================================${RESET}"
echo -e "${BOLD}       🚀 OPTIMALISASI & PEMBERSIHAN ARCH LINUX       ${RESET}"
echo -e "${CYAN}=====================================================${RESET}"

# Meminta akses sudo di awal
if [ "$EUID" -ne 0 ]; then
    echo -e "${BLUE}🔑 Memeriksa hak akses root (sudo)...${RESET}"
    sudo -v || { echo -e "${RED}❌ Membutuhkan hak akses sudo untuk melanjutkan.${RESET}"; exit 1; }
    # Perbarui timer sudo agar tidak meminta password lagi saat proses panjang
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# Tampilkan ukuran disk sebelum dibersihkan
echo -e "\n${BOLD}📊 Penggunaan Disk Sebelum Pembersihan:${RESET}"
df -h / | awk 'NR==1 || NR==2'
echo ""

# ------------------------------------------------------------------------------
# 1. Menghapus Paket Yatim (Orphaned Packages)
# ------------------------------------------------------------------------------
echo -e "${CYAN}-----------------------------------------------------${RESET}"
echo -e "${BOLD}📦 [1/6] Memeriksa Paket Yatim (Orphaned Packages)...${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"

orphans=$(pacman -Qtdq 2>/dev/null)

if [ -n "$orphans" ]; then
    echo -e "${YELLOW}Ditemukan paket yatim (dependensi yang tidak lagi digunakan):${RESET}"
    echo "$orphans" | sed 's/^/  - /'
    echo ""
    if confirm "Apakah Anda ingin menghapus semua paket yatim ini?" "Y"; then
        echo -e "${GREEN}🗑️  Menghapus paket yatim beserta dependensinya...${RESET}"
        sudo pacman -Rns --noconfirm $orphans
        echo -e "${GREEN}✅ Paket yatim berhasil dihapus!${RESET}"
    else
        echo -e "${BLUE}⏭️  Penghapusan paket yatim dilewati.${RESET}"
    fi
else
    echo -e "${GREEN}✅ Sistem bersih! Tidak ada paket yatim yang ditemukan.${RESET}"
fi

# ------------------------------------------------------------------------------
# 2. Membersihkan Cache Pacman
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}-----------------------------------------------------${RESET}"
echo -e "${BOLD}🧹 [2/6] Membersihkan Cache Pacman...${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"

if [ -d "/var/cache/pacman/pkg" ]; then
    cache_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')
    echo -e "Ukuran direktori cache pacman saat ini: ${BOLD}${cache_size}${RESET}"
fi

# Pastikan pacman-contrib terpasang untuk utilitas paccache
if ! command -v paccache &> /dev/null; then
    echo -e "${YELLOW}⚠️  'paccache' belum terpasang. Menginstal pacman-contrib...${RESET}"
    sudo pacman -S --needed --noconfirm pacman-contrib
fi

echo -e "\n${YELLOW}Pilihan pembersihan cache pacman:${RESET}"
echo -e "  1) ${BOLD}Rekomendasi:${RESET} Simpan 1 versi terbaru & hapus semua cache paket yang sudah di-uninstall"
echo -e "  2) ${BOLD}Pembersihan Penuh:${RESET} Hapus seluruh cache (Hemat ruang maksimal, tapi tidak bisa rollback tanpa download)"
echo -e "  3) Lewati langkah ini"

if [ "$AUTO_CONFIRM" = true ]; then
    pac_choice="1"
else
    read -rp "$(echo -e "${YELLOW}Pilih opsi [1/2/3] (default: 1): ${RESET}")" pac_choice
    pac_choice=${pac_choice:-1}
fi

case "$pac_choice" in
    1)
        echo -e "${GREEN}🧹 Menghapus cache versi lama (menyimpan 1 versi terbaru)...${RESET}"
        sudo paccache -rk1
        echo -e "${GREEN}🧹 Menghapus cache paket yang sudah di-uninstall...${RESET}"
        sudo paccache -ruk0
        echo -e "${GREEN}✅ Cache pacman berhasil dioptimalkan!${RESET}"
        ;;
    2)
        echo -e "${RED}⚠️  Menghapus seluruh cache pacman...${RESET}"
        sudo pacman -Scc --noconfirm
        echo -e "${GREEN}✅ Seluruh cache pacman telah dikosongkan!${RESET}"
        ;;
    *)
        echo -e "${BLUE}⏭️  Pembersihan cache pacman dilewati.${RESET}"
        ;;
esac

# ------------------------------------------------------------------------------
# 3. Membersihkan Cache AUR Helper (yay / paru)
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}-----------------------------------------------------${RESET}"
echo -e "${BOLD}✨ [3/6] Memeriksa & Membersihkan Cache AUR Helper...${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"

aur_cleaned=false

# Cek yay
if command -v yay &> /dev/null; then
    echo -e "Ditemukan AUR helper: ${BOLD}yay${RESET}"
    if [ -d "$HOME/.cache/yay" ]; then
        yay_cache_size=$(du -sh "$HOME/.cache/yay" 2>/dev/null | awk '{print $1}')
        echo -e "Ukuran cache build yay: ${BOLD}${yay_cache_size}${RESET}"
    fi

    if confirm "Bersihkan cache paket & build direktori yay?" "Y"; then
        echo -e "${GREEN}🧹 Membersihkan cache yay...${RESET}"
        yay -Sc --noconfirm
        rm -rf "$HOME/.cache/yay"/* 2>/dev/null
        echo -e "${GREEN}✅ Cache yay berhasil dibersihkan!${RESET}"
        aur_cleaned=true
    fi
fi

# Cek paru
if command -v paru &> /dev/null; then
    echo -e "Ditemukan AUR helper: ${BOLD}paru${RESET}"
    if [ -d "$HOME/.cache/paru" ]; then
        paru_cache_size=$(du -sh "$HOME/.cache/paru" 2>/dev/null | awk '{print $1}')
        echo -e "Ukuran cache paru: ${BOLD}${paru_cache_size}${RESET}"
    fi

    if confirm "Bersihkan cache paket & build direktori paru?" "Y"; then
        echo -e "${GREEN}🧹 Membersihkan cache paru...${RESET}"
        paru -Sc --noconfirm
        rm -rf "$HOME/.cache/paru"/* 2>/dev/null
        echo -e "${GREEN}✅ Cache paru berhasil dibersihkan!${RESET}"
        aur_cleaned=true
    fi
fi

if [ "$aur_cleaned" = false ] && ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo -e "${BLUE}ℹ️  Tidak ditemukan AUR helper (yay/paru).${RESET}"
fi

# ------------------------------------------------------------------------------
# 4. Membersihkan Systemd Journal Logs
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}-----------------------------------------------------${RESET}"
echo -e "${BOLD}📜 [4/6] Membersihkan Log Systemd (journalctl)...${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"

journal_size=$(journalctl --disk-usage 2>/dev/null)
echo -e "${journal_size}"

if confirm "Batasi ukuran journal log menjadi maks 100MB dan simpan maksimal 2 minggu terakhir?" "Y"; then
    echo -e "${GREEN}🧹 Memangkas systemd journal log...${RESET}"
    sudo journalctl --vacuum-time=2weeks --vacuum-size=100M
    echo -e "${GREEN}✅ Systemd journal berhasil dirapikan!${RESET}"
else
    echo -e "${BLUE}⏭️  Pembersihan journal log dilewati.${RESET}"
fi

# ------------------------------------------------------------------------------
# 5. Membersihkan Cache User & File Sementara
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}-----------------------------------------------------${RESET}"
echo -e "${BOLD}🗂️  [5/6] Membersihkan Cache Pengguna & Dump...${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"

# Thumbnail cache
if [ -d "$HOME/.cache/thumbnails" ]; then
    thumb_size=$(du -sh "$HOME/.cache/thumbnails" 2>/dev/null | awk '{print $1}')
    echo -e "Ukuran cache thumbnail: ${BOLD}${thumb_size}${RESET}"
    if confirm "Hapus cache thumbnail galeri/file manager?" "Y"; then
        rm -rf "$HOME/.cache/thumbnails"/* 2>/dev/null
        echo -e "${GREEN}✅ Cache thumbnail berhasil dibersihkan!${RESET}"
    fi
fi

# Core dumps (crash dumps)
if [ -d "/var/lib/systemd/coredump" ]; then
    if [ "$(sudo ls -A /var/lib/systemd/coredump 2>/dev/null)" ]; then
        if confirm "Hapus file coredump (catatan crash aplikasi) yang menumpuk?" "Y"; then
            sudo rm -rf /var/lib/systemd/coredump/*
            echo -e "${GREEN}✅ Coredump berhasil dibersihkan!${RESET}"
        fi
    fi
fi

# Flatpak unused runtimes (jika ada)
if command -v flatpak &> /dev/null; then
    echo -e "\n${BOLD}📦 Memeriksa runtime Flatpak yang tidak terpakai...${RESET}"
    if confirm "Hapus runtime Flatpak yang tidak terpakai (unused)?" "Y"; then
        flatpak uninstall --unused -y
        echo -e "${GREEN}✅ Flatpak yang tidak terpakai berhasil dihapus!${RESET}"
    fi
fi

# ------------------------------------------------------------------------------
# 6. Pengecekan Kesehatan Sistem (Health Check)
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}-----------------------------------------------------${RESET}"
echo -e "${BOLD}🔍 [6/6] Pengecekan Kesehatan Sistem...${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"

# Cek file .pacnew atau .pacsave
echo -e "Memeriksa file konfigurasi (.pacnew / .pacsave)..."
pacfiles=$(find /etc \( -name "*.pacnew" -o -name "*.pacsave" \) 2>/dev/null)
if [ -n "$pacfiles" ]; then
    echo -e "${YELLOW}⚠️  Perhatian: Ditemukan file .pacnew / .pacsave yang membutuhkan perhatian:${RESET}"
    echo "$pacfiles" | sed 's/^/  - /'
    echo -e "${BLUE}💡 Tip: Gunakan utilitas 'pacdiff' untuk menggabungkan konfigurasi tersebut.${RESET}"
else
    echo -e "${GREEN}✅ Tidak ada file .pacnew atau .pacsave yang tertinggal.${RESET}"
fi

# Cek service systemd yang gagal
echo -e "\nMemeriksa service systemd yang mengalami error / failed..."
failed_services=$(systemctl --failed --no-legend 2>/dev/null)
if [ -n "$failed_services" ]; then
    echo -e "${RED}⚠️  Ada service systemd yang gagal berjalan:${RESET}"
    systemctl --failed
    echo -e "${BLUE}💡 Tip: Cek log service terkait dengan 'systemctl status <nama-service>' atau 'journalctl -u <nama-service>'${RESET}"
else
    echo -e "${GREEN}✅ Semua service systemd berjalan normal (tidak ada yang failed).${RESET}"
fi

# ------------------------------------------------------------------------------
# Ringkasan Akhir
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}=====================================================${RESET}"
echo -e "${BOLD}🎉 PROSES OPTIMALISASI & PEMBERSIHAN SELESAI!${RESET}"
echo -e "${CYAN}=====================================================${RESET}"
echo -e "${BOLD}📊 Penggunaan Disk Setelah Pembersihan:${RESET}"
df -h / | awk 'NR==1 || NR==2'
echo -e "${CYAN}=====================================================${RESET}\n"
