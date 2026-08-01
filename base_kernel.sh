#!/bin/bash
set -eE
set -x

kernel=$(uname -a|awk '{ print $2 }')

if [ $kernel != "archlinux" ]; then
sudo apt install -y arch-install-scripts archlinux-keyring pacman-package-manager systemd-container libalpm13t64
#libalpm16
fi
sudo mkdir -p /etc/pacman.d
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d/
sudo cp  -a keyrings /usr/share/pacman
sudo cp etc/pacman.conf /etc
sudo cp  -a keyrings /usr/share/
sudo pacman-key --init
sudo pacman-key --populate archlinuxarm
sudo pacman -Syyu
if [ $kernel == "archlinux" ]; then
    sudo pacman -S --noconfirm arch-install-scripts
fi

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
sudo cp rockchip-kernel.sh my-add.txt make-dot-config.sh vp9-profile2-kernel-rkvdec.patch rkvdec-vdpu381-vp9.[ch] vp9-vdpu381-adapted.patch dvab-sarma-vp9-vdpu381.patch ./base_camp
# --as-pid2 を削除し、コンテナを起動
sudo systemd-nspawn -D ./base_camp --resolv-conf=replace-host /rockchip-kernel.sh /my-add.txt /make-dot-config.sh /vp9-profile2-kernel-rkvdec.patch

# 成果物の名前が .pkg.tar.zst になっている可能性を考慮して修正
rm -f base_camp/linux-aarch64-rockchip-chromebook-*
cp base_camp/linux-aarch64-rockchip-*.pkg.tar.* .
cp base_camp/arch-build-log.txt .
cp base_camp/Config-chg .

if [ $mem_size -gt 13 ]; then
        sudo umount base_camp
        sleep 2
fi 
