#!/usr/bin/env bash
# ==============================================================================
# CACHYOS ARCHINSTALL STANDALONE PATCHER & SETUP
# ==============================================================================
# Skrip ini sepenuhnya MANDIRI (STANDALONE) dan TIDAK memerlukan clone repo
# archinstall. Anda dapat mengunduh dan menjalankan file ini langsung di
# Arch Linux Live ISO resmi.
#
# Cara Penggunaan Cepat di Arch Live ISO:
#   curl -sL https://raw.githubusercontent.com/<user>/<repo>/main/cachyos-archinstall.sh | sudo bash
#   -atau-
#   sudo ./cachyos-archinstall.sh
#
# Untuk mengembalikan file asli sistem:
#   sudo ./cachyos-archinstall.sh --restore
# ==============================================================================

set -euo pipefail

# Warna terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

msg() { echo -e "${BLUE}${BOLD}[INFO]${NC} $1"; }
ok()  { echo -e "${GREEN}${BOLD}[OK]${NC} $1"; }
warn(){ echo -e "${YELLOW}${BOLD}[PERINGATAN]${NC} $1"; }
err() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; exit 1; }

# 1. Pastikan dijalankan sebagai root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "Skrip ini harus dijalankan dengan hak akses root (sudo)."
fi

# Banner
cat << 'EOF'
   ______           __            ____  _____
  / ____/___ ______/ /_  __  __  / __ \/ ___/
 / /   / __ `/ ___/ __ \/ / / / / / / /\__ \ 
/ /___/ /_/ / /__/ / / / /_/ / / /_/ /___/ / 
\____/\__,_/\___/_/ /_/\__, /  \____//____/  
                      /____/                 
  Standalone Archinstall CachyOS Auto-Patcher
EOF

# Mode Restore
if [[ "${1:-}" == "--restore" || "${1:-}" == "-r" ]]; then
    msg "Mengembalikan (restore) file bawaan archinstall dan pacman.conf..."
    python3 - << 'PYRESTORE'
import glob, shutil, os

found = False
for f in glob.glob('/usr/lib/python3*/site-packages/archinstall/**/*.orig', recursive=True):
    target = f[:-5]
    shutil.copy2(f, target)
    os.remove(f)
    print(f"  [+] Restored: {target}")
    found = True

if os.path.exists('/etc/pacman.conf.bak.cachyos'):
    shutil.copy2('/etc/pacman.conf.bak.cachyos', '/etc/pacman.conf')
    os.remove('/etc/pacman.conf.bak.cachyos')
    print("  [+] Restored: /etc/pacman.conf")
    found = True

if not found:
    print("  [-] Tidak ditemukan file backup (.orig).")
else:
    print("  [OK] Seluruh konfigurasi telah dikembalikan ke semula.")
PYRESTORE
    exit 0
fi

# 2. Deteksi Arsitektur Mikro CPU
msg "Mendeteksi kapabilitas arsitektur mikro CPU..."
ARCH_LEVEL="v1"
if /lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q "x86-64-v4 (supported, searched)"; then
    ARCH_LEVEL="v4"
    ok "CPU mendukung instruksi: x86-64-v4 (AVX-512)"
elif /lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q "x86-64-v3 (supported, searched)"; then
    ARCH_LEVEL="v3"
    ok "CPU mendukung instruksi: x86-64-v3 (AVX2)"
else
    msg "CPU menggunakan instruksi standar: x86-64"
fi

# 3. Impor GPG Key CachyOS
msg "Mengimpor dan memverifikasi GPG Key CachyOS (F3B607488DB35A47)..."
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com 2>/dev/null || \
pacman-key --recv-keys F3B607488DB35A47 --keyserver hkps://keys.openpgp.org 2>/dev/null || \
pacman-key --recv-keys F3B607488DB35A47 --keyserver pgp.mit.edu 2>/dev/null || \
err "Gagal mengunduh GPG Key CachyOS dari keyserver."

pacman-key --lsign-key F3B607488DB35A47
ok "GPG Key CachyOS berhasil diimpor & ditandatangani."

# 4. Siapkan File Mirrorlist Awal
msg "Menyiapkan file mirrorlist CachyOS..."
mkdir -p /etc/pacman.d

cat << 'EOF' > /etc/pacman.d/cachyos-mirrorlist
# CachyOS mirrorlist
Server = https://mirror.cachyos.org/repo/$arch/$repo
Server = https://geo.mirror.cachyos.org/repo/$arch/$repo
EOF

if [[ "$ARCH_LEVEL" == "v3" ]]; then
    cat << 'EOF' > /etc/pacman.d/cachyos-v3-mirrorlist
# CachyOS v3 mirrorlist
Server = https://mirror.cachyos.org/repo/$arch_v3/$repo
Server = https://geo.mirror.cachyos.org/repo/$arch_v3/$repo
EOF
elif [[ "$ARCH_LEVEL" == "v4" ]]; then
    cat << 'EOF' > /etc/pacman.d/cachyos-v4-mirrorlist
# CachyOS v4 mirrorlist
Server = https://mirror.cachyos.org/repo/$arch_v4/$repo
Server = https://geo.mirror.cachyos.org/repo/$arch_v4/$repo
EOF
fi

# 5. Konfigurasi /etc/pacman.conf Host
msg "Mengonfigurasi repositori CachyOS pada /etc/pacman.conf..."
python3 - << PYPACMAN
import os
import sys

conf = '/etc/pacman.conf'
bak = '/etc/pacman.conf.bak.cachyos'

with open(conf, 'r') as f:
    content = f.read()

if '[cachyos]' in content or '[cachyos-v3]' in content or '[cachyos-v4]' in content:
    print("  -> Repositori CachyOS sudah terkonfigurasi di /etc/pacman.conf")
    sys.exit(0)

# Simpan backup jika belum ada
if not os.path.exists(bak):
    with open(bak, 'w') as f:
        f.write(content)

arch_level = "$ARCH_LEVEL"
if arch_level == "v4":
    repos = (
        "[cachyos-v4]\nInclude = /etc/pacman.d/cachyos-v4-mirrorlist\n\n"
        "[cachyos-core-v4]\nInclude = /etc/pacman.d/cachyos-v4-mirrorlist\n\n"
        "[cachyos-extra-v4]\nInclude = /etc/pacman.d/cachyos-v4-mirrorlist\n\n"
        "[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n\n"
    )
elif arch_level == "v3":
    repos = (
        "[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n"
        "[cachyos-core-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n"
        "[cachyos-extra-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n\n"
        "[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n\n"
    )
else:
    repos = "[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n\n"

if '[core]' in content:
    new_content = content.replace('[core]', repos + '[core]', 1)
else:
    new_content = content + '\n' + repos

with open(conf, 'w') as f:
    f.write(new_content)
print("  -> Repositori CachyOS berhasil ditambahkan tepat di atas [core]")
PYPACMAN

# 6. Sinkronisasi Pacman & Pasang Paket Mirrorlist/Keyring Resmi
msg "Menyinkronkan database paket Pacman (-Sy)..."
pacman -Sy --noconfirm

msg "Memasang paket keyring & mirrorlist CachyOS..."
pacman -S --noconfirm --needed cachyos-keyring cachyos-mirrorlist
pacman-key --populate cachyos

if [[ "$ARCH_LEVEL" == "v3" ]]; then
    pacman -S --noconfirm --needed cachyos-v3-mirrorlist 2>/dev/null || true
elif [[ "$ARCH_LEVEL" == "v4" ]]; then
    pacman -S --noconfirm --needed cachyos-v4-mirrorlist 2>/dev/null || true
fi
ok "Keyring & mirrorlist CachyOS siap di host."

# 7. Patch Python Archinstall di Sistem Secara Otomatis
msg "Mendeteksi instalasi archinstall pada sistem..."
python3 - << 'PYPATCH'
import glob
import os
import re
import shutil
import sys
from pathlib import Path

# Cari lokasi archinstall pada site-packages sistem
arch_dir = None
try:
    import archinstall
    arch_dir = Path(archinstall.__file__).parent
except Exception:
    pass

if not arch_dir or not arch_dir.exists():
    candidates = glob.glob('/usr/lib/python3*/site-packages/archinstall')
    if candidates:
        arch_dir = Path(candidates[0])

if not arch_dir or not arch_dir.exists():
    print("  [PERINGATAN] Modul archinstall tidak ditemukan di site-packages sistem.")
    print("               Pastikan sistem memiliki paket archinstall terpasang.")
    sys.exit(0)

print(f"  -> Ditemukan archinstall di: {arch_dir}")

def backup_file(p: Path):
    orig = p.with_suffix(p.suffix + '.orig')
    if not orig.exists():
        shutil.copy2(p, orig)

# A. Patch package_types.py (Menambahkan kernel CachyOS & mengubah DEFAULT_KERNEL)
pt_file = arch_dir / 'lib' / 'models' / 'package_types.py'
if pt_file.exists():
    content = pt_file.read_text(encoding='utf-8')
    if 'LINUX_CACHYOS' not in content:
        backup_file(pt_file)
        cachy_kernels = (
            "\tLINUX_CACHYOS = 'linux-cachyos'\n"
            "\tLINUX_CACHYOS_BORE = 'linux-cachyos-bore'\n"
            "\tLINUX_CACHYOS_LTS = 'linux-cachyos-lts'\n"
        )
        match = re.search(r'(DEFAULT_KERNEL\s*(?::\s*[^=]+)?\s*=\s*)(Kernel\.\w+|[^\n]+)', content)
        if match:
            prefix = content[:match.start()]
            content = prefix + cachy_kernels + "\nDEFAULT_KERNEL: Final = Kernel.LINUX_CACHYOS" + content[match.end():]
        else:
            content = re.sub(r'(LINUX_RT_LTS\s*=[^\n]+)', r"\1\n" + cachy_kernels, content)
            content = re.sub(r'DEFAULT_KERNEL.*', "DEFAULT_KERNEL: Final = Kernel.LINUX_CACHYOS", content)
        pt_file.write_text(content, encoding='utf-8')
        print("  [+] Berhasil patch package_types.py (Default Kernel: linux-cachyos)")
    else:
        print("  [i] package_types.py sudah berisi konfigurasi CachyOS.")

# B. Patch installer.py (Menyertakan cachyos-keyring & mirrorlist ke target)
inst_file = arch_dir / 'lib' / 'installer.py'
if inst_file.exists():
    content = inst_file.read_text(encoding='utf-8')
    if 'cachyos' not in content:
        backup_file(inst_file)
        
        # Patch base_packages append
        m1 = re.search(r"^([ \t]*)for kernel in self\.kernels:\s*\n([ \t]*)self\._base_packages\.append\(kernel\)", content, re.MULTILINE)
        if m1:
            ind1 = m1.group(1)
            ind2 = m1.group(2)
            cachy_strap = (
                f"\n{ind2}if 'cachyos' in kernel:\n"
                f"{ind2}\tfor pkg in ['cachyos-keyring', 'cachyos-mirrorlist']:\n"
                f"{ind2}\t\tif pkg not in self._base_packages:\n"
                f"{ind2}\t\t\tself._base_packages.append(pkg)\n"
                f"{ind2}\tfor v_name in ['cachyos-v3-mirrorlist', 'cachyos-v4-mirrorlist', 'cachyos-znver4-mirrorlist']:\n"
                f"{ind2}\t\tif Path(f'/etc/pacman.d/{{v_name}}').exists() and v_name not in self._base_packages:\n"
                f"{ind2}\t\t\tself._base_packages.append(v_name)"
            )
            content = content[:m1.end()] + cachy_strap + content[m1.end():]

        # Patch populate keyring in chroot
        m2 = re.search(r"^([ \t]*)pacman_conf\.persist\(\)", content, re.MULTILINE)
        if m2:
            ind = m2.group(1)
            cachy_pop = (
                f"\n\n{ind}if any('cachyos' in k for k in self.kernels):\n"
                f"{ind}\ttry:\n"
                f"{ind}\t\tself.arch_chroot('pacman-key --populate archlinux cachyos')\n"
                f"{ind}\texcept Exception as err:\n"
                f"{ind}\t\tdebug(f'CachyOS keyring populate notice: {{err}}')"
            )
            content = content[:m2.end()] + cachy_pop + content[m2.end():]

        inst_file.write_text(content, encoding='utf-8')
        print("  [+] Berhasil patch installer.py (Auto-strap CachyOS Keyring & Mirrorlist)")
    else:
        print("  [i] installer.py sudah di-patch.")

# C. Patch config.py (Persist mirrorlist ke /mnt/etc/pacman.d/)
cfg_file = arch_dir / 'lib' / 'pacman' / 'config.py'
if cfg_file.exists():
    content = cfg_file.read_text(encoding='utf-8')
    if 'cachyos' not in content:
        backup_file(cfg_file)
        m3 = re.search(r"^([ \t]*)PACMAN_CONF\.copy\(self\._config_remote_path, preserve_metadata=True\)", content, re.MULTILINE)
        if m3:
            ind = m3.group(1)
            cachy_cpy = (
                f"\n\n{ind}target_pacman_d = self._config_remote_path.parent / 'pacman.d'\n"
                f"{ind}if target_pacman_d.exists():\n"
                f"{ind}\timport shutil\n"
                f"{ind}\tfor mirrorlist_file in Path('/etc/pacman.d').glob('cachyos*'):\n"
                f"{ind}\t\tdest_file = target_pacman_d / mirrorlist_file.name\n"
                f"{ind}\t\tif not dest_file.exists():\n"
                f"{ind}\t\t\tshutil.copy2(mirrorlist_file, dest_file)"
            )
            content = content[:m3.end()] + cachy_cpy + content[m3.end():]
            cfg_file.write_text(content, encoding='utf-8')
            print("  [+] Berhasil patch config.py (Persist CachyOS mirrorlists to target)")
    else:
        print("  [i] config.py sudah di-patch.")
PYPATCH

ok "Patch archinstall sistem selesai!"

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  Pemasangan Selesai! archinstall Siap Digunakan.                ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "Informasi Sistem:"
echo -e " - Tingkat Arsitektur CPU : ${CYAN}${ARCH_LEVEL}${NC}"
echo -e " - Kernel Default         : ${CYAN}linux-cachyos${NC}"
echo -e " - Repositori             : ${CYAN}CachyOS (prioritas di atas [core])${NC}"
echo -e " - Target Keyring         : ${CYAN}Otomatis dikonfigurasi saat pacstrap${NC}"
echo ""
echo -e "Jalankan instalasi Arch Linux cukup dengan perintah:"
echo -e "  ${YELLOW}${BOLD}archinstall${NC}"
echo ""

read -rp "Apakah Anda ingin langsung menjalankan archinstall sekarang? [Y/n]: " run_now
run_now="${run_now:-Y}"

if [[ "$run_now" =~ ^[Yy]$ ]]; then
    msg "Memulai archinstall..."
    exec archinstall
fi
