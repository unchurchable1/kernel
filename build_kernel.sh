#!/bin/bash

REVISION="0.2"
HARDWARE="ASUS.R540S"

LINUX_VERSION="4.13"
TARGET="linux-source-$LINUX_VERSION"

show_usage() {
	echo "Usage: $(basename $0) [--clean]"
	exit
}

check_arguments() {
	case $# in
		0)
			return
			;;
		1)
			if [ $1 = "--clean" ]
			then
				CLEAN=true
				return
			fi
			;;
		*)
			;;
	esac
	show_usage
}

is_installed() {
	which $@ >/dev/null
	return $?
}

apt_install() {
	echo "Missing dependency: $@"
	sudo apt install -qq --assume-yes $@
}

check_dependencies() {
	is_installed fakeroot || apt_install fakeroot
	is_installed make-kpkg || apt_install kernel-package
}

check_kernel() {
	cd $(dirname $0)
	if [ ! -d $TARGET ]
	then
		if [ ! -e /usr/src/$TARGET.tar.xz ]
		then
			apt_install $TARGET
		fi
		tar -xf /usr/src/$TARGET.tar.xz
	fi
}

clean_kernel() {
	cd $TARGET
	if [ $CLEAN ]
	then
		make-kpkg clean
		make distclean
	fi
}

config_kernel() {
	# start with default config
	cat arch/x86/configs/x86_64_defconfig \
		| sed 's|CONFIG_LOGO=y|# CONFIG_LOGO is not set|' \
		| sed 's|CONFIG_NO_HZ=y|# CONFIG_NO_HZ is not set|' \
		| sed 's|CONFIG_HZ_1000=y|CONFIG_HZ_250=y|' \
		> .config

	# ASUS R540S hardware
	echo 'CONFIG_ACPI_WMI=y' >> .config
	echo 'CONFIG_ASUS_LAPTOP=y' >> .config
	echo 'CONFIG_ASUS_NB_WMI=y' >> .config
	echo 'CONFIG_ASUS_WIRELESS=y' >> .config
	echo 'CONFIG_ASUS_WMI=y' >> .config
	echo 'CONFIG_ATH9K=y' >> .config
	echo 'CONFIG_I2C_DESIGNWARE_CORE=y' >> .config
	echo 'CONFIG_I2C_DESIGNWARE_PLATFORM=y' >> .config
	echo 'CONFIG_I2C_HID=y' >> .config
	echo 'CONFIG_INPUT_MOUSEDEV=y' >> .config
	echo 'CONFIG_INPUT_PCSPKR=y' >> .config
	echo 'CONFIG_INT340X_THERMAL=y' >> .config
	echo 'CONFIG_INT3406_THERMAL=y' >> .config
	echo 'CONFIG_INTEL_RAPL=y' >> .config
	echo 'CONFIG_ITCO_WDT=y' >> .config
	echo 'CONFIG_ITCO_VENDOR_SUPPORT=y' >> .config
	echo 'CONFIG_MOUSE_ELAN_I2C=y' >> .config
	echo 'CONFIG_MOUSE_ELAN_I2C_I2C=y' >> .config
	echo 'CONFIG_MOUSE_ELAN_I2C_SMBUS=y' >> .config
	echo 'CONFIG_MOUSE_PS2_ELANTECH=y' >> .config
	echo 'CONFIG_MOUSE_SYNAPTICS_I2C=y' >> .config
	echo 'CONFIG_SND_HDA_CODEC_HDMI=y' >> .config
	echo 'CONFIG_SND_HDA_CODEC_REALTEK=y' >> .config
	echo 'CONFIG_SND_HDA_GENERIC=y' >> .config
	echo 'CONFIG_SND_HDA_PREALLOC_SIZE=2048' >> .config
	echo 'CONFIG_SND_SOC=y' >> .config
	echo 'CONFIG_SND_SOC_COMPRESS=y' >> .config
	echo 'CONFIG_SND_SOC_INTEL_SST=y' >> .config
	echo 'CONFIG_SND_SOC_INTEL_SST_ACPI=y' >> .config
	echo 'CONFIG_SND_SOC_INTEL_SST_MATCH=y' >> .config
	echo 'CONFIG_SND_SST_ATOM_HIFI2_PLATFORM=y' >> .config
	echo 'CONFIG_USB_XHCI_HCD=y' >> .config

	# extra
	echo 'CONFIG_GENERIC_IRQ_CHIP=y' >> .config
	echo 'CONFIG_INPUT_MOUSEDEV_PSAUX=y' >> .config
	echo 'CONFIG_KERNEL_XZ=y' >> .config
	echo 'CONFIG_SQUASHFS=m' >> .config

	make olddefconfig
}

make_kernel() {
	make-kpkg --initrd \
		--append-to-version=-custom \
		--jobs=$(cat /proc/cpuinfo | grep ^processor | wc -l) \
		--revision=$REVISION.$HARDWARE \
		--rootcmd=fakeroot \
		kernel_headers \
		kernel_image

	echo -e '\nDone!\n'
	ls -lh ../linux-*.deb
}

time (
	check_arguments $@
	check_dependencies
	check_kernel
	clean_kernel
	config_kernel
	make_kernel
)
