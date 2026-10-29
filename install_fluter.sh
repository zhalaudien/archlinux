#!/bin/bash

# ==============================================================================
# Script Instalasi & Konfigurasi Lengkap Flutter & Android SDK di Arch Linux
# ==============================================================================
# Menghasilkan lingkungan Flutter yang siap pakai:
#   1. Dependensi Sistem: OpenJDK 17, Clang, CMake, Ninja, Pkgconf, GTK3, Mesa-utils
#   2. Flutter SDK: Channel stable di ~/development/flutter
#   3. Android SDK: ~/Android/Sdk lengkap dengan cmdline-tools (latest)
#   4. Android Build-Tools & Platforms: 34.0.0 & 36.0.0, android-34 & android-36
#   5. Otomatis menerima seluruh lisensi Android SDK & Flutter
#   6. Konfigurasi Environment & PATH permanen di Bash, Zsh, dan Fish Shell
#   7. Verifikasi akhir dengan flutter doctor
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

# Dapatkan user asli non-root jika dipanggil dengan sudo
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(whoami)}"
    USER_HOME="$HOME"
fi

# Fungsi untuk menjalankan perintah sebagai user target
run_as_user() {
    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        sudo -u "$REAL_USER" bash -c "$1"
    else
        bash -c "$1"
    fi
}

# Fungsi untuk menjalankan perintah sebagai root (sudo jika bukan root)
run_as_root() {
    if [ "$EUID" -eq 0 ]; then
        bash -c "$1"
    else
        sudo bash -c "$1"
    fi
}

echo -e "${CYAN}=====================================================${RESET}"
echo -e "${BOLD}       🚀 INSTALASI FLUTTER & ANDROID SDK (ARCH)      ${RESET}"
echo -e "${CYAN}=====================================================${RESET}"
echo -e "User Target     : ${BOLD}${REAL_USER}${RESET}"
echo -e "Direktori Home  : ${BOLD}${USER_HOME}${RESET}"
echo -e "Flutter Path    : ${BOLD}${USER_HOME}/development/flutter${RESET}"
echo -e "Android SDK Path: ${BOLD}${USER_HOME}/Android/Sdk${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}\n"

# ------------------------------------------------------------------------------
# 1. Instalasi Dependensi Sistem & Toolchain
# ------------------------------------------------------------------------------
echo -e "${BLUE}📦 [1/6] Menginstal paket sistem & toolchain pembangunan...${RESET}"
SYSTEM_PKGS=(
    jdk17-openjdk
    clang
    cmake
    ninja
    pkgconf
    gtk3
    mesa-utils
    git
    curl
    wget
    unzip
    tar
    base-devel
)

run_as_root "pacman -S --needed --noconfirm ${SYSTEM_PKGS[*]}"

# Pastikan default Java environment diarahkan ke Java 17
if command -v archlinux-java &> /dev/null; then
    echo -e "${GREEN}☕ Mengatur default Java ke java-17-openjdk...${RESET}"
    run_as_root "archlinux-java set java-17-openjdk || true"
fi

# ------------------------------------------------------------------------------
# 2. Instalasi Flutter SDK (Channel Stable)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🐦 [2/6] Memeriksa & mengunduh Flutter SDK...${RESET}"
DEV_DIR="$USER_HOME/development"
FLUTTER_DIR="$DEV_DIR/flutter"

run_as_user "mkdir -p '$DEV_DIR'"

if [ ! -d "$FLUTTER_DIR" ]; then
    echo -e "${GREEN}📥 Kloning Flutter repository (channel: stable)...${RESET}"
    run_as_user "git clone https://github.com/flutter/flutter.git -b stable '$FLUTTER_DIR'"
else
    echo -e "${GREEN}🔄 Direktori Flutter sudah ada, memperbarui...${RESET}"
    run_as_user "git -C '$FLUTTER_DIR' fetch --tags && git -C '$FLUTTER_DIR' checkout stable"
fi

# ------------------------------------------------------------------------------
# 3. Instalasi Android SDK & Command-Line Tools
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🤖 [3/6] Mengonfigurasi Android SDK & Command-Line Tools...${RESET}"
ANDROID_HOME="$USER_HOME/Android/Sdk"
CMDLINE_DIR="$ANDROID_HOME/cmdline-tools/latest"

run_as_user "mkdir -p '$ANDROID_HOME'"

if [ ! -f "$CMDLINE_DIR/bin/sdkmanager" ]; then
    echo -e "${GREEN}📥 Mengunduh Android Command-Line Tools dari Google...${RESET}"
    CMDLINE_ZIP_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    TEMP_EXTRACT="/tmp/cmdline-tools-extract"
    
    rm -rf "$TEMP_EXTRACT" /tmp/cmdline-tools.zip
    mkdir -p "$TEMP_EXTRACT"
    
    wget -q --show-progress "$CMDLINE_ZIP_URL" -O /tmp/cmdline-tools.zip
    unzip -qo /tmp/cmdline-tools.zip -d "$TEMP_EXTRACT"
    
    run_as_user "mkdir -p '$ANDROID_HOME/cmdline-tools'"
    run_as_user "rm -rf '$CMDLINE_DIR'"
    run_as_user "mv '$TEMP_EXTRACT/cmdline-tools' '$CMDLINE_DIR'"
    
    rm -rf "$TEMP_EXTRACT" /tmp/cmdline-tools.zip
    echo -e "${GREEN}✅ Android Command-Line Tools berhasil dipasang!${RESET}"
else
    echo -e "${GREEN}✅ Android Command-Line Tools sudah tersedia.${RESET}"
fi

# ------------------------------------------------------------------------------
# 4. Instalasi Android Build-Tools, Platforms, & Lisensi
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}📱 [4/6] Menginstal Platform-Tools, Build-Tools, & SDK Platforms...${RESET}"

SDK_PACKAGES=(
    "platform-tools"
    "build-tools;34.0.0"
    "build-tools;36.0.0"
    "platforms;android-34"
    "platforms;android-36"
)

# Jalankan sdkmanager dengan ANDROID_HOME yang tepat
SDKMANAGER_CMD="export ANDROID_HOME='$ANDROID_HOME'; yes | '$CMDLINE_DIR/bin/sdkmanager' --sdk_root='$ANDROID_HOME' '${SDK_PACKAGES[@]}'"
run_as_user "$SDKMANAGER_CMD"

# Menerima semua lisensi Android SDK
echo -e "${GREEN}📜 Menerima lisensi Android SDK...${RESET}"
run_as_user "export ANDROID_HOME='$ANDROID_HOME'; yes | '$CMDLINE_DIR/bin/sdkmanager' --sdk_root='$ANDROID_HOME' --licenses >/dev/null 2>&1 || true"

# ------------------------------------------------------------------------------
# 5. Konfigurasi Environment Variables & PATH pada Shell
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}⚙️  [5/6] Mengonfigurasi variabel lingkungan & PATH pada shell...${RESET}"

# Path tambahan untuk Flutter & Android SDK
EXPORT_BLOCK_BASH=$(cat <<'EOF'

# Android SDK & Flutter
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
EOF
)

# Tambahkan ke ~/.bashrc jika belum ada
if [ -f "$USER_HOME/.bashrc" ] && ! grep -q "Android SDK & Flutter" "$USER_HOME/.bashrc"; then
    echo "$EXPORT_BLOCK_BASH" >> "$USER_HOME/.bashrc"
    echo -e "${GREEN}✅ Path ditambahkan ke ~/.bashrc${RESET}"
fi

# Tambahkan ke ~/.zshrc jika file ada
if [ -f "$USER_HOME/.zshrc" ] && ! grep -q "Android SDK & Flutter" "$USER_HOME/.zshrc"; then
    echo "$EXPORT_BLOCK_BASH" >> "$USER_HOME/.zshrc"
    echo -e "${GREEN}✅ Path ditambahkan ke ~/.zshrc${RESET}"
fi

# Tambahkan ke Fish Shell config
FISH_CONFIG="$USER_HOME/.config/fish/config.fish"
if [ -f "$FISH_CONFIG" ] && ! grep -q "Android SDK & Flutter" "$FISH_CONFIG"; then
    cat <<'EOF' >> "$FISH_CONFIG"

# Android SDK & Flutter
set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx PATH $HOME/development/flutter/bin $PATH
set -gx PATH $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools $ANDROID_HOME/emulator $PATH
EOF
    echo -e "${GREEN}✅ Path ditambahkan ke ~/.config/fish/config.fish${RESET}"
fi

# Pastikan permission home user tetap tepat
run_as_root "chown -R '$REAL_USER:$REAL_USER' '$USER_HOME/development' '$USER_HOME/Android' '$USER_HOME/.config/fish' 2>/dev/null || true"

# Konfigurasi sdk-path langsung di Flutter config
echo -e "${GREEN}🔧 Mengaitkan Android SDK ke konfigurasi Flutter...${RESET}"
run_as_user "export PATH='$FLUTTER_DIR/bin:$PATH'; '$FLUTTER_DIR/bin/flutter' config --android-sdk '$ANDROID_HOME' --no-analytics"

# Menerima lisensi dari flutter doctor
echo -e "${GREEN}📜 Menyetujui flutter android-licenses...${RESET}"
run_as_user "export ANDROID_HOME='$ANDROID_HOME'; export PATH='$FLUTTER_DIR/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH'; yes | '$FLUTTER_DIR/bin/flutter' doctor --android-licenses >/dev/null 2>&1 || true"

# ------------------------------------------------------------------------------
# 6. Precache & Verifikasi Akhir
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🩺 [6/6] Menjalankan precache dan flutter doctor...${RESET}"
run_as_user "export ANDROID_HOME='$ANDROID_HOME'; export PATH='$FLUTTER_DIR/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH'; '$FLUTTER_DIR/bin/flutter' precache --linux --android"
run_as_user "export ANDROID_HOME='$ANDROID_HOME'; export PATH='$FLUTTER_DIR/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH'; '$FLUTTER_DIR/bin/flutter' doctor -v"

echo -e "\n${CYAN}=====================================================${RESET}"
echo -e "${BOLD}🎉 INSTALASI & KONFIGURASI FLUTTER SELESAI!${RESET}"
echo -e "${CYAN}=====================================================${RESET}"
echo -e "Flutter Location : ${BOLD}$FLUTTER_DIR/bin/flutter${RESET}"
echo -e "Android SDK      : ${BOLD}$ANDROID_HOME${RESET}"
echo -e "Java Version     : OpenJDK 17"
echo -e "${CYAN}=====================================================${RESET}"
echo -e "${YELLOW}💡 Catatan: Buka terminal baru atau ketik 'source ~/.config/fish/config.fish' agar PATH langsung aktif.${RESET}\n"
