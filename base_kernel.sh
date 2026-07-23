#!/bin/bash
set -eE
set -x


sudo apt install -y arch-install-scripts archlinux-keyring pacman-package-manager libarchive-tools systemd-container libalpm13t64 
# libalpm16
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp  -a keyrings /usr/share/pacman
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp etc/pacman.conf /etc
sudo pacman-key --init
sudo sudo pacman-key --populate archlinuxarm
sudo pacman -S --noconfirm --need arch-install-scripts
sudo pacman -Syyu

rm -rf linux-aarch64-*
rm -rf base_camp && mkdir base_camp
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
        sudo mount -t tmpfs -o size=10G tmpfs base_camp
fi
sudo cp -a etc keyrings ./base_camp
sudo pacstrap ./base_camp base sudo arch-install-scripts archlinux-keyring base-devel git kmod bc dtc uboot-tools 

# ARCH-ORG
# 設定ファイルとスクリプトをコンテナへコピー
sudo cp rockchip-kernel.sh my-add.txt make-dot-config.sh ./base_camp
# --as-pid2 を削除し、コンテナを起動
sudo systemd-nspawn -D ./base_camp --resolv-conf=replace-host /rockchip-kernel.sh /my-add.txt /make-dot-config.sh

# 成果物の名前が .pkg.tar.zst になっている可能性を考慮して修正
rm -f base_camp/linux-aarch64-rockchip-chromebook-*
cp base_camp/linux-aarch64-rockchip-*.pkg.tar.* .
cp base_camp/arch-build-log.txt .
cp base_camp/config-chg .
echo "kernel_version=$( ls linux-aarch64-rockchip-headers-[0-9]*.pkg.tar.* | awk -F- '{ print $5 }' )" > kernel_version
if [ $mem_size -gt 13 ]; then
        sudo umount base_camp
        sleep 2
fi 
