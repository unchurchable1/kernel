#!/bin/sh

REVISION="0.1"
VERSION="4.13"
TARGET="linux-source-$VERSION"

show_usage() {
	echo "Usage: sudo $(basename $0)"
	exit
}

root_or_gtfo() {
	[ $(id -u) = 0 ] || show_usage
}

is_installed() {
	which $@ >/dev/null
	return $?
}

install_quietly() {
	apt install -qq --assume-yes $@
}

check_dependencies() {
	is_installed make-kpkg || install_quietly kernel-package
}

check_kernel() {
	cd /usr/src
	if [ ! -d $TARGET ]
	then
		if [ ! -e $TARGET.tar.xz ]
		then
			install_quietly $TARGET
		fi
		tar -xf $TARGET.tar.xz
	fi
}

clean_kernel() {
	cd $TARGET
	make-kpkg clean
	make distclean
}

config_kernel() {
	cat arch/x86/configs/x86_64_defconfig \
		| sed 's|CONFIG_LOGO=y|# CONFIG_LOGO is not set|' \
		> .config

	echo 'CONFIG_ASUS_LAPTOP=m' >> .config
	echo 'CONFIG_ASUS_NB_WMI=m' >> .config
	echo 'CONFIG_ASUS_WIRELESS=m' >> .config
	echo 'CONFIG_ASUS_WMI=m' >> .config
	echo 'CONFIG_ATH9K=m' >> .config
	echo 'CONFIG_INPUT_JOYDEV=m' >> .config
	echo 'CONFIG_INT340X_THERMAL=m' >> .config
	echo 'CONFIG_INT3406_THERMAL=m' >> .config
	echo 'CONFIG_INTEL_RAPL=m' >> .config
	echo 'CONFIG_ITCO_WDT=m' >> .config
	echo 'CONFIG_MOUSE_ELAN_I2C=m' >> .config
	echo 'CONFIG_SND_HDA_CODEC_HDMI=m' >> .config
	echo 'CONFIG_SND_HDA_CODEC_REALTEK=m' >> .config
	echo 'CONFIG_SND_HDA_GENERIC=m' >> .config
	echo 'CONFIG_SND_SOC=m' >> .config
	echo 'CONFIG_SND_SOC_INTEL_SST=m' >> .config
	echo 'CONFIG_SND_SOC_INTEL_SST_ACPI=m' >> .config
	echo 'CONFIG_SND_SOC_INTEL_SST_MATCH=m' >> .config
	echo 'CONFIG_SND_SST_ATOM_HIFI2_PLATFORM=m' >> .config
	echo 'CONFIG_USB_XHCI_HCD=m' >> .config

	echo 'CONFIG_ITCO_VENDOR_SUPPORT=y' >> .config
	echo 'CONFIG_SND_HDA_PREALLOC_SIZE=2048' >> .config
	echo 'CONFIG_SND_SOC_COMPRESS=y' >> .config

	make olddefconfig
}

make_kernel() {
	make-kpkg --initrd \
		--jobs=$(cat /proc/cpuinfo | grep ^processor | wc -l) \
		--revision=$REVISION.$SUDO_USER \
		kernel_image
}

root_or_gtfo
check_dependencies
check_kernel
clean_kernel
config_kernel
make_kernel
