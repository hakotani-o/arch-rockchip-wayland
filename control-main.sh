#!/bin/bash
set -eE

start_time=`date`

	rm -rf my-pkg && mkdir my-pkg
	./das-u-boot.sh orangepi-5-rk3588s_defconfig 2>&1|tee log
	./base_kernel.sh
	./pkg_labwc.sh
	./base_rootfs.sh
	sudo ./disk_image.sh orangepi-5 rk3588s-orangepi-5
	./das-u-boot.sh orangepi-5-plus-rk3588_defconfig
	sudo ./disk_image.sh orangepi-5-plus rk3588-orangepi-5-plus

echo "$start_time"
date
