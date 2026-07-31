#!/bin/bash
set -eE

# ====================================================================
# 📺 [対策会議] VP9ハードウェアデコード復活 ＆ 縦動画（Shorts）バグ修正パッ
チ
# ====================================================================
#echo "Downloading VP9 hardware decode patch for rkvdec2..."
#wget -O ../999-v4l2-rockchip-vdec-vp9-profile2-stride-fix.patch \
#https://github.com/dongioia/rock5bplus-rkvdec2/releases/download/chromium-150.0.7871.114-nv15-10bit/vp9-profile2-kernel-rkvdec.patch
mv ~/vp9-profile2-kernel-rkvdec.patch ..
mv ~/rkvdec-vdpu381-vp9.[ch] drivers/media/platform/rockchip/rkvdec/

grep -m1 pkgver ../../PKGBUILD > prepare
source ./prepare
        echo "patch-$pkgver"
        patch -p1 < ../patch-$pkgver

for i in ../*.patch
do
        echo $i
        patch -p1 < $i
done

# TAMESI
sed -i 's/INSTALL_DTBS_PATH="${pkgdir}\/boot\/dtbs"/INSTALL_DTBS_PATH="${pkgdir}\/boot\/dtbs\/$kernver"/' ../../PKGBUILD
sed -i '/conflicts=/d' ../../PKGBUILD 
sed -i 's/echo "Installing modules..."/mv "${pkgdir}\/boot\/Image.gz" "${pkgdir}\/boot\/vmlinuz-${kernver}"\n  rm "${pkgdir}\/boot\/Image" \n\n\n echo "Installing modules..."/' ../../PKGBUILD


#make defconfig
cat ../../config > .config
  ./scripts/kconfig/merge_config.sh -m .config /home/builder/my-add.txt
  ./scripts/config --set-val DEBUG_INFO_NONE y
  ./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
  ./scripts/config --disable DEBUG_INFO_DWARF4
  ./scripts/config --disable DEBUG_INFO_DWARF5
  make olddefconfig
  
  #./scripts/diffconfig .config ../../config | grep "^ " | awk '$2 != "n"' | sed 's/-//' | awk '{ print "CONFIG_" $1 "=" $4 }' >> /home/builder/my-add.txt
  #rm .config
  #make defconfig
  #./scripts/kconfig/merge_config.sh -m .config /home/builder/my-add.txt
  #./scripts/config --set-val DEBUG_INFO_NONE y
  #./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
  #./scripts/config --disable DEBUG_INFO_DWARF4
  #./scripts/config --disable DEBUG_INFO_DWARF5
  #make olddefconfig

  sed -i 's/CONFIG_LOCALVERSION="-ARCH"/CONFIG_LOCALVERSION=""/' .config
  cp .config ../../config
  cp .config ../config
sudo cp .config /Config-chg
  make prepare

