#!/bin/bash
set -eE
set -x

kernel=$(uname -a|awk '{ print $2 }')

if [ $kernel != "archlinux" ]; then
sudo apt install -y arch-install-scripts archlinux-keyring pacman-package-manager systemd-container libalpm13t64 
# libalpm16
sudo pacman-key --init
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp  -a keyrings /usr/share/
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp etc/pacman.conf /etc
sudo pacman-key --populate archlinuxarm
else
sudo pacman -S --noconfirm arch-install-scripts
fi
sudo pacman -Syyu

sudo rm -rf base_camp && sudo mkdir base_camp
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
        sudo mount -t tmpfs -o size=10G tmpfs base_camp
fi
sudo pacstrap ./base_camp base sudo arch-install-scripts archlinux-keyring
sudo cp pacstrap.sh ai-wayland.sh firstboot-growroot.sh ./base_camp
sudo cp -a etc keyrings ./base_camp
sudo cp linux-aarch64-*-aarch64.pkg.tar.xz  u-boot-menu-4.2.4.tar.gz ./base_camp
sudo systemd-nspawn -D ./base_camp --resolv-conf=replace-host --as-pid2 /pacstrap.sh
cp base_camp/Arch-linux.rootfs.tar.gz .
cp base_camp/kernel_version .
if [ $mem_size -gt 13 ]; then
        sudo umount base_camp
        sleep 2
fi

