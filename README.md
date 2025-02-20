# archlinux

auto config untuk update setelah install, install fish dan oh-my-posh, install tema, install php untuk programing, kusus untuk pengguna ArchLinux yang baru install base system dan desktop gnome-shell

## Installation

Jika belum install git install terlebih dahulu

```
sudo pacman -S git
```

Clone ke home.

```
cd
git clone https://github.com/zhalaudien/archlinux.git
cd archlinux/
```

update system.

```
sudo ./afterinstall.sh
```

Install Fish dan oh-my-posh

```
sudo ./install_fish.sh
```

Install tema.

```
sudo ./install_tema.sh
```

Install PHP, apache, mariadb, phpmyadmin.

```
sudo ./install_tema.sh
```

## Update Script

Update script jika ada update dan perbaikan

```
cd archlinux
git pull
```
