#!/bin/sh

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
	cat /boot/config-$(uname -r) \
		| sed 's|# CONFIG_DRM_VBOXVIDEO is not set|CONFIG_DRM_VBOXVIDEO=m|' \
		> .config
	make olddefconfig
}

make_kernel() {
	make-kpkg --initrd \
		--jobs=$(cat /proc/cpuinfo | grep ^processor | wc -l) \
		--revision=$VERSION.vbox \
		kernel_image
}

root_or_gtfo
check_dependencies
check_kernel
clean_kernel
config_kernel
make_kernel
