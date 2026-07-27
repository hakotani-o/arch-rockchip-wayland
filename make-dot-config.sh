#!/bin/bash

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


make defconfig
  ./scripts/kconfig/merge_config.sh -m .config /home/builder/my-add.txt
  ./scripts/config --set-val DEBUG_INFO_NONE y
  ./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
  ./scripts/config --disable DEBUG_INFO_DWARF4
  ./scripts/config --disable DEBUG_INFO_DWARF5
  make olddefconfig
  ./scripts/diffconfig .config ../../config | grep "^ " | awk '$2 != "n"' | sed 's/-//' | awk '{ print "CONFIG_" $1 "=" $4 }' >> /home/builder/my-add.txt
  rm .config
  make defconfig
  ./scripts/kconfig/merge_config.sh -m .config /home/builder/my-add.txt
  ./scripts/config --set-val DEBUG_INFO_NONE y
  ./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
  ./scripts/config --disable DEBUG_INFO_DWARF4
  ./scripts/config --disable DEBUG_INFO_DWARF5
  make olddefconfig

  sed -i 's/CONFIG_LOCALVERSION="-ARCH"/CONFIG_LOCALVERSION=""/' .config
  cp .config ../../config
  cp .config ../config
sudo cp .config /Config-chg
  make prepare

