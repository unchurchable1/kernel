#!/bin/bash

REVISION="0.7"
HARDWARE="ASUS.R540S"

LINUX_VERSION="4.14.7"
TARGET="linux-$LINUX_VERSION"
TARGET_URL="https://cdn.kernel.org/pub/linux/kernel/v4.x/"
PATCH_DIR="debian_patches"
PATCH_URL="https://anonscm.debian.org/cgit/kernel/linux.git/plain/debian/patches/"

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

config_mkkpkg() {
	CONF=/etc/kernel-pkg.conf
	NAME=$(git config --get user.name)
	MAIL=$(git config --get user.email)

	if [ -n "$NAME" ] && [ -n "$MAIL" ]
	then
		grep -q "$NAME" $CONF || \
			sudo sed -i "s|maintainer := .*$|maintainer := $NAME|" $CONF

		grep -q "$MAIL" $CONF || \
			sudo sed -i "s|email := .*$|email := $MAIL|" $CONF
	fi
}

check_kernel() {
	cd $(dirname $0)
	if [ ! -d $TARGET ]
	then
		if [ ! -e .src/$TARGET.tar.xz ]
		then
			mkdir -p .src
			wget -q $TARGET_URL/$TARGET.tar.xz -O .src/$TARGET.tar.xz
		fi
		tar -xf .src/$TARGET.tar.xz
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

patch_kernel() {
	for PATCH in $(wget -q $PATCH_URL/series -O - | grep -v '#')
	do
		if [ ! -e $PATCH_DIR/$PATCH ]
		then
			mkdir -p $PATCH_DIR/$(dirname $PATCH)
			wget -q $PATCH_URL/$PATCH -O $PATCH_DIR/$PATCH
			git apply --check < $PATCH_DIR/$PATCH 2>/dev/null
			if [ $? != 0 ]
			then
				echo "Skipping patch: $PATCH"
			else
				patch -p1 -uNs < $PATCH_DIR/$PATCH
			fi
		fi
	done
}

config_kernel() {
	cat /boot/config-$(uname -r) | sed "s|=m|=n|" > .config
	for MODULE in $(cat ../modules.list)
	do
		sed -i "s|$MODULE=n|$MODULE=m|" .config
	done
	for OPTION in $(cat ../options.list)
	do
		sed -i "s|# $OPTION is not set|$OPTION=y|" .config
	done
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
	config_mkkpkg
	check_kernel
	clean_kernel
	patch_kernel
	config_kernel
	make_kernel
)
