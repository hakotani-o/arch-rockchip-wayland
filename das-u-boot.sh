#!/bin/bash
set -eE

# 引数チェック
if [ -z "$1" ]; then
    echo "Usage: $0 <board_defconfig>"
    exit 1
fi

# OS判定（ホスト名ではなく /etc/os-release で確実に判定）
if grep -qi "arch" /etc/os-release 2>/dev/null; then
    IS_ARCH=1
else
    IS_ARCH=0
fi

if [ "$IS_ARCH" -eq 0 ]; then
    # Debian / Ubuntu 系
    sudo apt-get update && sudo apt-get -y install build-essential gcc-aarch64-linux-gnu bison \
    debootstrap flex libssl-dev bc rsync kmod cpio xz-utils fakeroot parted \
    udev dosfstools uuid-runtime device-tree-compiler python3 \
    python-is-python3 fdisk debhelper python3-pyelftools python3-setuptools \
    python3-pkg-resources swig libfdt-dev libpython3-dev gawk \
    git ncurses-dev libelf-dev libgnutls28-dev libdw-dev curl
else
    # Arch Linux 系
    sudo pacman -S --noconfirm --needed base-devel uboot-tools dtc bc gcc flex bison git wget curl python swig python-pyelftools python-pkgconfig python-pip
fi

rm -rf arm64
mkdir arm64

mem_size=$(free --giga | grep Mem | awk '{print $2}')
if [ "$mem_size" -gt 2 ]; then
    # OpenSSLとU-Bootを同時にビルドするため、tmpfsを2Gに拡張
    sudo mount -t tmpfs -o size=2G tmpfs arm64
fi

# エラー終了時にも確実にアンマウント・後片付けするためのトラップ設定
cleanup() {
    cd "$OLDPWD" 2>/dev/null || true
    if mountpoint -q arm64; then
        sudo umount arm64 || true
    fi
    rm -rf arm64
}
trap cleanup EXIT

cd arm64

# ---------------------------------------------------------
# 1. OpenSSL 3.6.5 のローカルビルド（システムのOpenSSLが4.x系の場合のみ自動実行）
# ---------------------------------------------------------
HOST_OPENSSL_FLAGS=()
if openssl version | grep -qE "^OpenSSL 4\."; then
    echo "Detected OpenSSL 4.x. Building OpenSSL 3.6.5 locally..."
    OPENSSL_VER="3.6.5"
    OPENSSL_PREFIX="$(pwd)/openssl-3.6-install"

    wget "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VER/openssl-${OPENSSL_VER}.tar.gz"
    tar -xf "openssl-${OPENSSL_VER}.tar.gz"
    cd "openssl-${OPENSSL_VER}"
    ./Configure --prefix="$OPENSSL_PREFIX" --openssldir="$OPENSSL_PREFIX" no-docs
    make -j$(nproc)
    make install_sw
    cd ..
    rm -rf "openssl-${OPENSSL_VER}" "openssl-${OPENSSL_VER}.tar.gz"

    HOST_OPENSSL_FLAGS=(
        HOSTCFLAGS="-I${OPENSSL_PREFIX}/include"
        HOSTLDFLAGS="-L${OPENSSL_PREFIX}/lib64 -L${OPENSSL_PREFIX}/lib -Wl,-rpath,${OPENSSL_PREFIX}/lib64 -Wl,-rpath,${OPENSSL_PREFIX}/lib"
    )
fi

# ---------------------------------------------------------
# 2. Rockchip バイナリ (rkbin) の取得
# ---------------------------------------------------------
git clone --depth 1 https://github.com/rockchip-linux/rkbin

DDR=$(ls rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v*.bin)
BL31=$(ls rkbin/bin/rk35/rk3588_bl31*.elf)
export BL31="$(pwd)/$BL31"
export ROCKCHIP_TPL="$(pwd)/$DDR"

echo ""
echo "export ROCKCHIP_TPL=$ROCKCHIP_TPL"
echo "export BL31=$BL31"
echo ""

export PATH="$(pwd)/tools/binman:$PATH"
echo "PATH=$PATH"
echo ""

# ---------------------------------------------------------
# 3. U-Boot のクローンとビルド
# ---------------------------------------------------------
git clone --depth 1 https://gitlab.com/u-boot/u-boot.git -b v2026.04
cd u-boot

if [ ! -f "configs/$1" ]; then
    echo "$1 not found in configs"
    exit 1
fi

echo 'CONFIG_SYS_SOC="rk3588"' >> "configs/$1"
sed -i 's/#ifndef CONFIG_XPL_BUILD/#ifndef CONFIG_XPL_BUILD\n\n #define BOOT_TARGETS    "nvme scsi mmc"\n\n/' include/configs/rockchip-common.h

if [ "$IS_ARCH" -eq 0 ]; then
    make clean "$1"
    make "${HOST_OPENSSL_FLAGS[@]}" -j$(nproc)
else
    make NO_SDL=1 CONFIG_PYLIBFDT=n clean "$1"
    make NO_SDL=1 CONFIG_PYLIBFDT=n "${HOST_OPENSSL_FLAGS[@]}" -j$(nproc)
fi

cp u-boot-rockchip.bin ../..
echo ""
echo "Build succeeded! Flash command:"
echo "dd if=u-boot-rockchip.bin of=/dev/sdX seek=1 bs=32k conv=fsync"

cd ../..
echo "DISK usage"
df -h arm64
if [ $mem_size -gt 2 ]; then
        sudo umount arm64
        sleep 2
fi              
rm -rf arm64

