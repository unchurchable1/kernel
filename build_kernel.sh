#!/bin/bash

REVISION="1.5"
HARDWARE="ASUS.notebook"
VERSION="custom"

LINUX_VERSION="4.18"
TARGET="linux-source-$LINUX_VERSION"

SELF=$(basename $0)

log() {
    printf "* [$SELF] : $@\n"
}

show_usage() {
    printf "Usage: $SELF [OPTION]...\n\n"
    printf "Options:\n"
    printf "  -c      clean kernel source tree; runs 'make-kpkg clean'\n"
    printf "  -p      purge kernel source tree; runs 'rm -rf $TARGET'\n"
    printf "  -i      install kernel packages when the build is done\n"
    printf "  -h      display this help and exit\n"
    exit
}

wrong_usage() {
    printf "$SELF: invalid option -- '$@'\n"
    printf "Try '$SELF -h' for more information.\n"
    exit
}

check_arguments() {
    while getopts ":cpih" OPT
    do
        case $OPT in
            c)
                CLEAN=true
                ;;
            p)
                PURGE=true
                ;;
            i)
                INSTALL=true
                ;;
            h)
                show_usage
                ;;
            \?)
                wrong_usage $OPTARG
                ;;
        esac
    done
}

check_config() {
    uname -r | grep -q $VERSION
    if [ $? == 0 ]
    then
        printf "Currently running a custom kernel\n"
        printf "Switch to a stock kernel before compiling\n"
        exit
    fi
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
    if [ $PURGE ]
    then
        log "Purging $TARGET"
        rm -rf $TARGET
    fi
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
    fi
}

config_kernel() {
    log "Configuring $TARGET"
    # start with current config; disable all modules
    cat /boot/config-$(uname -r) | sed "s|=m|=n|" > .config
    # re-enable wanted modules
    for MODULE in $(cat ../modules.list)
    do
        sed -i "s|$MODULE=n|$MODULE=m|" .config
    done
    # enable additional options
    for OPTION in $(cat ../enable.list)
    do
        sed -i "s|# $OPTION is not set|$OPTION=y|" .config
    done
    # disable additional options
    for OPTION in $(cat ../disable.list)
    do
        sed -i "s|$OPTION=.*||" .config
    done
    # generate new config
    make olddefconfig
}

build_kernel() {
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

    if [ $INSTALL ]
    then
        log "Installing $TARGET"
        SUBLEVEL=$(grep ^SUBLEVEL Makefile | sed 's|SUBLEVEL = ||')
        for PKG in headers image
        do
            sudo dpkg -i ../linux-"$PKG"-"$LINUX_VERSION"."$SUBLEVEL"-"$VERSION"_"$REVISION"."$HARDWARE"_amd64.deb
        done
    fi
}

# setup
check_arguments $@
check_config
check_dependencies
config_mkkpkg
check_kernel

# compile
time (
    clean_kernel
    config_kernel
    build_kernel
)
