#!/bin/bash

#chg_version=$( grep -m1 pkgver= ../../PKGBUILD | sed 's/pkgver=//' | awk -F. '{ print $1 }')
chg_patchlevel=$( grep -m1 pkgver= ../../PKGBUILD | sed 's/pkgver=//' | awk -F. '{ print $2 }')
chg_sublevel=$( grep -m1 pkgver= ../../PKGBUILD | sed 's/pkgver=//' | awk -F. '{ print $3 }')
#org_version=$( grep -m1 "VERSION = " Makefile )
org_patchlevel=$( grep -m1 "PATCHLEVEL = " Makefile )
org_sublevel=$( grep -m1 "SUBLEVEL = " Makefile )

#sed -i "s/$org_version/VERSION = $chg_version/" Makefile
sed -i "s/$org_patchlevel/PATCHLEVEL = $chg_patchlevel/" Makefile
sed -i "s/$org_sublevel/SUBLEVEL = $chg_sublevel/" Makefile

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
sudo cp .config /config-chg
  make prepare

