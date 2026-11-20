#!/bin/bash
set -eE

sudo pacman-key --init
sudo cp -a keyrings /usr/share/pacman
sudo pacman-key --populate archlinuxarm

sudo rm -rf ./mnt && sudo mkdir ./mnt
sudo pacstrap ./mnt base vim sudo 

#####    fcitx5-im fcitx5-mozc

#[ GNOME ]
sudo pacman -S --noconfirm --root ./mnt \
    gnome-desktop gnome-tweaks gdm \
    networkmanager ttf-dejavu noto-fonts-cjk \
    pipewire-pulse alsa-utils zenity cloud-guest-utils \
    e2fsprogs gvfs udisks2 clapper mpv vulkan-tools mesa-docs \
    mkinitcpio linux-firmware util-linux \
    xorg-xwayland

sudo pacman -S --noconfirm --root ./mnt \
    mesa gnome-shell gnome-control-center gnome-console nautilus \
    gnome-keyring xdg-user-dirs-gtk gnome-shell-extension-appindicator \
    dosfstools mtools parted gptfdisk arch-install-scripts zstd xz

#    firefox chromium thunderbird git bash-completion \


# kernel (カスタムカーネルパッケージの流し込み)
yes | sudo pacman -U --root ./mnt /linux-aarch64-rockchip-7.3.5-1-7.3.5-1-aarch64.pkg.tar.xz
yes | sudo pacman -U --root ./mnt /linux-aarch64-rockchip-7.3.5-1-headers-7.3.5-1-aarch64.pkg.tar.xz


# u-boot-update
sudo tar zxvf /u-boot-menu-4.2.4.tar.gz -C ./mnt/
mkdir -p ./mnt/usr/share/u-boot-menu/conf.d
	cat << 'EOF' > ./mnt/usr/share/u-boot-menu/conf.d/archlinux.conf
	U_BOOT_UPDATE="true"
	U_BOOT_PROMPT="1"
	U_BOOT_PARAMETERS="$(cat /etc/kernel/cmdline)"
	U_BOOT_TIMEOUT="20" 
EOF
echo "rootwait rw console=ttyS2,1500000 console=tty1" > ./mnt/etc/kernel/cmdline

echo "ELECTRON_OZONE_PLATFORM_HINT=wayland" >> ./mnt/etc/environment
echo "XDG_SESSION_TYPE=wayland" >> ./mnt/etc/environment

sudo ./ai-wayland.sh
kernel_version=$( ls ./mnt/boot/vmlinuz*| sed 's/vmlinuz-/ /'| sed 's/-aarch64-rockchip//' | sed 's/-/ /g' | awk '{ print $2 "-" $3 }' )
echo "kernel_version=$kernel_version" > /kernel_version
# キャッシュクリア
yes | sudo pacman -Scc --root ./mnt 


cd mnt && sudo bsdtar -zcf /Arch-linux.rootfs.tar.gz --xattrs ./*
cd ..

