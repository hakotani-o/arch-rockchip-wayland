#!/bin/bash
set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR


cleanup_loopdev() {
    local loop="$1"

    sync --file-system
    sync

    sleep 1

    if [ -b "${loop}" ]; then
        for part in "${loop}"p*; do
            if mnt=$(findmnt -n -o target -S "$part"); then
                umount "${mnt}"
            fi
        done
        losetup -d "${loop}"
    fi
}

wait_loopdev() {
    local loop="$1"
    local seconds="$2"

    until test $((seconds--)) -eq 0 -o -b "${loop}"; do sleep 1; done

    ((++seconds))

    ls -l "${loop}" &> /dev/null
}

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

export  LC_ALL=C 
export  LC_CTYPE=C
export  LANGUAGE=C
export  LANG=C


# ホスト環境（ビルドを回しているPC）に必要なツール

sudo apt-get update && sudo apt-get -y install uuid-runtime 

rootfs="./Arch-linux.rootfs.tar.gz"
rootfs="$(readlink -f "$rootfs")"
if [[ "$(basename "${rootfs}")" != *".rootfs.tar.gz" || ! -e "${rootfs}" ]]; then
    echo "Error: $(basename "${rootfs}") must be a rootfs tarfile"
    exit 1
fi

now=`date +%F`
# Create an empty disk image
img="./Arch-linux-aarch64-$1-$now.img"
size="$(( $(gzip -l "${rootfs}" | awk 'NR==2 {print $2}')   / 1024 / 1024 ))"
truncate -s "$(( size + 2048 ))M" "${img}"

# Create loop device for disk image
loop="$(losetup -f)"
losetup -P "${loop}" "${img}"
disk="${loop}"

# Cleanup loopdev on early exit
trap 'cleanup_loopdev ${loop}' EXIT

# Ensure disk is not mounted
mount_point=/tmp/mnt
umount "${disk}"* 2> /dev/null || true
umount ${mount_point}/* 2> /dev/null || true
mkdir -p ${mount_point}

    # Setup partition table
    dd if=/dev/zero of="${disk}" count=4096 bs=512
    parted --script "${disk}" \
    mklabel gpt \
    mkpart primary ext4 16MiB 100%

    # Create partitions
    {
        echo "t"
        echo "1"
        echo "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
        echo "w"
    } | fdisk "${disk}" &> /dev/null || true

    partprobe "${disk}"

    partition_char="$(if [[ ${disk: -1} == [0-9] ]]; then echo p; fi)"

    sleep 1

    wait_loopdev "${disk}${partition_char}1" 60 || {
        echo "Failure to create ${disk}${partition_char}1 in time"
        exit 1
    }

    sleep 1

    # Generate random uuid for bootfs
    root_uuid=$(uuidgen)

    # Create filesystems on partitions
    dd if=/dev/zero of="${disk}${partition_char}1" bs=1KB count=10 > /dev/null
    mkfs.ext4 -U "${root_uuid}" -L desktop-rootfs "${disk}${partition_char}1"

    # Mount partitions
    mkdir -p ${mount_point}/writable
    mount "${disk}${partition_char}1" ${mount_point}/writable


# Copy the rootfs to root partition
bsdtar -zxpf "${rootfs}" -C ${mount_point}/writable

fdt_name="/boot/dtbs/rockchip/$2.dtb"


# Create fstab entries
echo "# <file system>     <mount point>  <type>  <options>   <dump>  <fsck>" > ${mount_point}/writable/etc/fstab
echo "UUID=${root_uuid,,} /              ext4    defaults,noatime    0       1" >> ${mount_point}/writable/etc/fstab

# Write bootloader to disk image
if [ -f "./u-boot-rockchip.bin" ]; then
    dd if="./u-boot-rockchip.bin" of="${loop}" seek=1 bs=32k conv=fsync
else
	echo "./u-boot-rockchip.bin not found"
	exit 1
fi

{
echo '#!/bin/bash'
echo ""
echo '# extlinux.conf の出力先パス'
echo 'EXTLINUX_DIR="/boot/extlinux"'
echo 'EXTLINUX_CONF="${EXTLINUX_DIR}/extlinux.conf"'
echo ""
echo "# ディレクトリが存在しない場合は作成"
echo 'mkdir -p "${EXTLINUX_DIR}"'
echo ""
echo '# extlinux.conf の生成'
echo 'cat << EOF1 > "${EXTLINUX_CONF}"'
echo 'default arch'
echo 'menu title Arch Linux Boot Menu'
echo 'prompt 1'
echo 'timeout 50'
echo ''
echo 'label arch'
echo '    menu label Arch Linux'
echo '    linux /boot/Image.gz'
echo '    initrd /boot/initramfs-linux.img'
echo '    # デバイスツリーのパスは環境に合わせて変更してください'
echo "    fdt ${fdt_name}"
echo "    append root=UUID=${root_uuid,,} rw console=ttyS0,115200"
echo "EOF1"
echo ''
} > ${mount_point}/writable/usr/local/bin/generate-extlinux.sh
echo "Generated extlinux.conf U-Boot configuration."
sudo chmod +x ${mount_point}/writable/usr/local/bin/generate-extlinux.sh

mountpoint="${mount_point}/writable"

mount dev-live -t devtmpfs "$mountpoint/dev"
mount devpts-live -t devpts -o nodev,nosuid "$mountpoint/dev/pts"
mount proc-live -t proc "$mountpoint/proc"
mount sysfs-live -t sysfs "$mountpoint/sys"
mount securityfs -t securityfs "$mountpoint/sys/kernel/security"

# 【SDDM移行対応】lxdm から sddm に変更、不要なsudoを除去
chroot ${mount_point}/writable/ /bin/bash -c "
systemctl enable sddm
systemctl enable firstboot-growroot.service
systemctl enable NetworkManager.service
systemctl enable systemd-timesyncd.service
"
# ====================================================================================

# User & Sudoers設定（タイポの修正とwheel自動有効化）
# Arch Linuxでは標準で /etc/sudoers の wheel グループコメントアウトを解除します
chroot ${mount_point}/writable/ /bin/bash -c "useradd -m -G wheel,users,video setupadmin"
sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' ${mount_point}/writable/etc/sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' ${mount_point}/writable/etc/sudoers
echo 'setupadmin ALL=(ALL) NOPASSWD: ALL' >> ${mount_point}/writable/etc/sudoers.d/setupadmin

# setupadmin gui-wizard.sh 起動設定
mkdir -p ${mount_point}/writable/home/setupadmin/.config/labwc
echo '/usr/local/bin/gui-wizard.sh &' > ${mount_point}/writable/home/setupadmin/.config/labwc/autostart

# GitHubビルド用に mkinitcpio.conf を調整 (autodetectの削除、SATAモジュールの強制追加)
cp ${mount_point}/writable/etc/mkinitcpio.conf ${mount_point}/writable/etc/mkinitcpio.conf.org
sed -i 's/^MODULES=(.*/MODULES=(ahci sd_mod nvme mmc_block ext4)/' ${mount_point}/writable/etc/mkinitcpio.conf
sed -i 's/^HOOKS=(.*/HOOKS=(base systemd modconf kms keyboard sd-vconsole block filesystems fsck)/' ${mount_point}/writable/etc/mkinitcpio.conf

# その後、前述した通りchroot内で再ビルド
chroot ${mount_point}/writable/ /bin/bash -c "mkinitcpio -P && /usr/local/bin/generate-extlinux.sh && sync"

sync --file-system
sync

umount "$mountpoint/sys/kernel/security"
umount "$mountpoint/sys"
umount "$mountpoint/proc"
umount "$mountpoint/dev/pts"
umount "$mountpoint/dev"
umount "$mountpoint"

# Umount partitions
trap '' EXIT

# Remove loop device
losetup -d "${loop}"

# Exit trap is no longer needed
echo -e "\nCompressing $(basename "${img}.xz")\n"
#xz -v -9 -T0 "${img}"
#rm "${img}"
exit 0

