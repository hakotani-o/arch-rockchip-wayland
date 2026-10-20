#!/bin/bash
set -eE
set -x

kernel=$(uname -a|awk '{ print $2 }')

if [ $kernel != "archlinux" ]; then
sudo apt install -y arch-install-scripts archlinux-keyring pacman-package-manager systemd-container libalpm13t64 
# libalpm16
# libalpm13t64 
sudo pacman-key --init
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp  -a keyrings /usr/share/
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp etc/pacman.conf /etc
sudo pacman-key --populate archlinuxarm
else
sudo pacman -S --noconfirm arch-install-scripts
fi
#sudo pacman -Syyu

sudo rm -rf base_camp && sudo mkdir base_camp
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
        sudo mount -t tmpfs -o size=8G tmpfs base_camp
fi
sudo pacstrap ./base_camp base sudo arch-install-scripts archlinux-keyring
sudo cp rockchip-labwc.sh ./base_camp
sudo cp -a etc keyrings ./base_camp
sudo mkdir -p ./base_camp/MY-rockchip
sudo systemd-nspawn -D ./base_camp --resolv-conf=replace-host --as-pid2 /rockchip-labwc.sh
cp base_camp/MY-rockchip/* my-pkg
cp base_camp/arch-labwc.txt .
if [ $mem_size -gt 13 ]; then
        sudo umount base_camp
	rm -rf base_camp
        sleep 2
fi

