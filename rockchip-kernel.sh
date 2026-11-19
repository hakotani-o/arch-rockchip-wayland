#!/bin/bash

# 引数のチェック（my-add.txt が指定されているか）
if [ -z "$2" ]; then
    echo "エラー: 第1引数に my-add.txt のパスを指定してください。"
    exit 1
fi

KOKO=$(pwd)
# === ここから一般ユーザー「builder」として実行 ===
set -eE
set -x

TAGS="7.3"
# Gitの初期化とSparse Checkout設定
git init
git config core.sparseCheckout true
git branch -m master
git remote add origin https://github.com/archlinuxarm/PKGBUILDs/
echo "core/linux-aarch64/*" >> .git/info/sparse-checkout

# 必要なフォルダだけをプル
git fetch origin master
git checkout 22ff581c2082c6e6325ba52211ffdcf3e16ffd2a

yes | sudo pacman -S pacman-contrib
cd core/linux-aarch64
echo "------------- core/linux-aarch64 ------------------"
ls -la
echo "---------------------------------------------------"

# =========================================================
# ✨ 【超重要】PKGBUILDのprepare関数に、自動設定マージの仕掛けを注入
# =========================================================
# 1. 本家Rockchipのベース設定を生成 (make rockchip_defconfig)
# 2. my-add.txt (JMB582やsystemd用設定) を自動マージ
# 3. 巨大なデバッグ情報を無効化してメモリ不足・容量圧迫を回避
# 4. make olddefconfig で新パラメータを自動補完し、configファイルとして確定させる
# =========================================================
cp PKGBUILD ~
sed -i "s|make prepare| $KOKO/make-dot-config.sh $KOKO|" PKGBUILD
CURRENT_PKGVER=$( grep ^pkgver PKGBUILD | cut -d= -f2 )
CURRENT_PKGREL=$( grep ^pkgrel PKGBUILD | cut -d= -f2 )
CURRENT_VERSION=$CURRENT_PKGVER-$CURRENT_PKGREL
sed -i "s|pkgbase=linux-aarch64|pkgbase=linux-aarch64-rockchip-$CURRENT_VERSION|" PKGBUILD
sed -i 's|git apply --whitespace=nowarn ../patch-${pkgver}|# git  apply --whitespace=nowarn ../patch-${pkgver}\n echo "git  apply --whitespace=nowarn ../patch-${pkgver}"\n|' PKGBUILD
sed -i 's|git apply|# git apply|' PKGBUILD
cp linux-aarch64.install linux-aarch64-rockchip-${CURRENT_VERSION}.install
cp linux-aarch64-chromebook.install linux-aarch64-rockchip-${CURRENT_VERSION}-chromebook.install
sed -i 's|default_image="/boot/initramfs-linux.img"|default_image="/boot/initrd.img-${ALL_kver}"|' linux.preset

sed -i '/_AC97_/d' config
sed -i '/CONFIG_WLAN_VENDOR_SILABS/d' config
sed -i '/^CONFIG_INFINIBAND/d' config
sed -i '/^CONFIG_SND_SOC_FSL_/d' config
sed -i '/^CONFIG_SND_HDA/d' config
sed -i '/^CONFIG_SND_SOC_IMX_AUDMUX/d' config
sed -i '/^CONFIG_DRM_LONTIUM_LT8912B/d' config
sed -i '/^CONFIG_DRM_LONTIUM_LT9611/d' config
sed -i '/^CONFIG_DRM_LONTIUM_LT9611UXC/d' config
sed -i '/^CONFIG_DRM_TOSHIBA_TC358767/d' config
sed -i '/^CONFIG_DRM_TI_TFP410/d' config
# dont delete CONFIG_DRM_TI_SN65DSI86
#sed -i '/^CONFIG_DRM_TI_SN65DSI86/d' config
sed -i '/^CONFIG_DRM_I2C_ADV7511/d' config
sed -i '/^CONFIG_DRM_BOCHS/d' config
sed -i '/^CONFIG_DRM_CIRRUS_QEMU/d' config
sed -i '/^CONFIG_DRM_LIMA/d' config

sed -i '/^CONFIG_BROADCOM_PHY/d' config
sed -i '/^CONFIG_BCM54140_PHY/d' config
sed -i '/^CONFIG_BCM7XXX_PHY/d' config
sed -i '/^CONFIG_BCM87XX_PHY/d' config
sed -i '/^CONFIG_MICROCHIP_PHY/d' config


sed -i '/^CONFIG_VIRTIO_/d' config
sed -i '/^CONFIG_DEBUG_KERNEL/d' config


# ソースの展開とチェックサム更新
updpkgsums
#makepkg -od --noconfirm

# チェックサムの再更新
#updpkgsums

# カーネルのビルド（--noconfirm で依存関係の自動インストールを許可）
MAKEFLAGS="-j$(nproc)" makepkg -sf 2>&1|tee $KOKO/arch-build-log.txt


# === 一般ユーザーでの実行ここまで ===

# 出来上がったパッケージをコンテナのルート「/」に配置
rm ./linux-aarch64-rockchip-*chromebook*-aarch64.pkg.tar.*
cp ./linux-aarch64-rockchip-*-aarch64.pkg.tar.* $KOKO

# ビルドログを root 権限で / に退避（base_kernel.sh が回収できるようにする）
cp /home/builder/*.txt $KOKO 2>/dev/null || true

