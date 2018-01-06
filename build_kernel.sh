#!/bin/bash

REVISION="0.9"
HARDWARE="ASUS.R540S"
VERSION="custom"

DEBIAN_BRANCH="sid"
LINUX_VERSION="4.14"
TARGET="linux-source-$LINUX_VERSION"

SELF=$(basename $0)

log() {
	echo "* [$SELF] : $@"
}

show_usage() {
	echo "Usage: $SELF [--clean]"
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
	log "Missing dependency: $@"
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
		log "Configuring kernel-package"
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
		if [ ! -e /usr/src/$TARGET.tar.xz ]
		then
			apt_install $TARGET
		fi
		log "Unpacking $TARGET.tar.xz"
		tar -xf /usr/src/$TARGET.tar.xz
	fi
}

clean_kernel() {
	cd $TARGET
	if [ $CLEAN ]
	then
		log "Cleaning $TARGET"
		make-kpkg clean
		make distclean
	fi
}

config_kernel() {
	log "Configuring $TARGET"
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
	log "Compiling $TARGET"
	make-kpkg \
		--append-to-version=-$VERSION \
		--initrd \
		--jobs=$(grep ^processor /proc/cpuinfo | wc -l) \
		--revision=$REVISION.$HARDWARE \
		--rootcmd=fakeroot \
		kernel_headers \
		kernel_image

	log "Done!"
	ls -lh ../linux-*.deb
}

time (
	check_arguments $@
	check_dependencies
	config_mkkpkg
	check_kernel
	clean_kernel
	config_kernel
	make_kernel
)
