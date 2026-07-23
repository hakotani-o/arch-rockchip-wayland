#!/bin/bash
set -eE

sudo pacman-key --init
sudo cp -a keyrings /usr/share/pacman
sudo pacman-key --populate archlinuxarm
sudo pacman -Syyu

sudo rm -rf ./mnt && sudo mkdir ./mnt
sudo pacstrap ./mnt base vim sudo 

# 【LXQt + Labwc (Wayland) 仕様へ最適化】
# 不要な xorg / lxde を削り、sddm / labwc / lxqt / pcmanfm-qt を投入
sudo pacman -S --noconfirm --root ./mnt \
    sddm labwc lxqt pcmanfm-qt qt6-wayland \
    networkmanager network-manager-applet ttf-dejavu noto-fonts-cjk \
    pipewire-pulse alsa-utils pavucontrol zenity cloud-guest-utils \
    e2fsprogs gvfs udisks2 clapper mpv vulkan-tools mesa-utils \
    mkinitcpio linux-firmware util-linux 

# kernel (カスタムカーネルパッケージの流し込み)
yes | sudo pacman -U --root ./mnt /linux-aarch64-rockchip-7.1.4-1-aarch64.pkg.tar.*
yes | sudo pacman -U --root ./mnt /linux-aarch64-rockchip-headers-7.1.4-1-aarch64.pkg.tar.*

sudo ./ai-wayland.sh

# キャッシュクリア
yes | sudo pacman -Scc --root ./mnt 

cd mnt && sudo bsdtar -zcf /Arch-linux.rootfs.tar.gz --xattrs ./*
cd ..

