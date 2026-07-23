#!/bin/bash
set -eE
set -x


sudo apt install -y arch-install-scripts archlinux-keyring pacman-package-manager libarchive-tools systemd-container libalpm16
# libalpm13t64 
sudo pacman-key --init
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp  -a keyrings /usr/share/
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp etc/pacman.conf /etc
sudo sudo pacman-key --populate archlinuxarm
sudo pacman -S --noconfirm --need arch-install-scripts
sudo pacman -Syyu

sudo rm -rf base_camp && sudo mkdir base_camp
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
        sudo mount -t tmpfs -o size=10G tmpfs base_camp
fi
sudo pacstrap ./base_camp base sudo arch-install-scripts archlinux-keyring
sudo cp pacstrap.sh ai-wayland.sh firstboot-growroot.sh ./base_camp
sudo cp -a etc keyrings ./base_camp
sudo cp linux-aarch64-*-aarch64.pkg.tar.xz ./base_camp
sudo systemd-nspawn -D ./base_camp --resolv-conf=replace-host --as-pid2 /pacstrap.sh
cp base_camp/Arch-linux.rootfs.tar.gz .
if [ $mem_size -gt 13 ]; then
        sudo umount base_camp
        sleep 2
fi

