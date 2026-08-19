#!/bin/bash
set -eE

# ====================================================================
# 📺 [対策会議] VP9ハードウェアデコード復活 ＆ 縦動画（Shorts）バグ修正パッチ
# ====================================================================
echo "Downloading VP9 hardware decode patch for rkvdec2..."
mkdir minimyth2 && cd minimyth2
# 3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
# 3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
# 3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
# 3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
# 3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
# 3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
# 3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch

# add 4 patch for AV01 4K Hardware decode not work 2026/08/18
# 3611-arm64-dtsi-rk3588-add-av1-iommu-nodes.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3611-arm64-dtsi-rk3588-add-av1-iommu-nodes.patch
# 3563-iommu-Add-verisilicon-IOMMU-driver.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3563-iommu-Add-verisilicon-IOMMU-driver.patch
# 3566-media-v4l2-core-Initialize-h264-frame_mbs_only_flag-as-1.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3566-media-v4l2-core-Initialize-h264-frame_mbs_only_flag-as-1.patch
# 3567-media-verisilicon-AV1-Restore-IOMMU-context-before-d.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3567-media-verisilicon-AV1-Restore-IOMMU-context-before-d.patch
cd ..


grep -m1 pkgver ../../PKGBUILD > prepare
source ./prepare
        echo "patch-$pkgver"
        patch -p1 < ../patch-$pkgver

for i in ../*.patch
do
        echo $i
        patch -p1 < $i
done

# minimyth2 patch
for i in minimyth2/*.patch
do
        echo $i
        patch -p1 < $i
done

# TAMESI
sed -i 's/INSTALL_DTBS_PATH="${pkgdir}\/boot\/dtbs"/INSTALL_DTBS_PATH="${pkgdir}\/boot\/dtbs\/$kernver"/' ../../PKGBUILD
sed -i '/conflicts=/d' ../../PKGBUILD 
sed -i 's/echo "Installing modules..."/mv "${pkgdir}\/boot\/Image.gz" "${pkgdir}\/boot\/vmlinuz-${kernver}"\n  rm "${pkgdir}\/boot\/Image" \n\n\n echo "Installing modules..."/' ../../PKGBUILD
sed -i 's/unset LDFLAGS/unset LDFLAGS\n export KCFLAGS="-march=armv8-a+crypto+crc -mtune=cortex-a76.cortex-a55" \n/' ../../PKGBUILD

#make defconfig
cat ../../config > .config
  ./scripts/kconfig/merge_config.sh -m .config /home/builder/my-add.txt
  ./scripts/config --set-val DEBUG_INFO_NONE y
  ./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
  ./scripts/config --disable DEBUG_INFO_DWARF4
  ./scripts/config --disable DEBUG_INFO_DWARF5
  ./scripts/config --disable COMPILE_TEST
  ./scripts/config --disable USBPCWATCHDOG
  ./scripts/config --disable SSB
  ./scripts/config --disable BCMA

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

