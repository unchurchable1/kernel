#!/bin/bash

REVISION="0.5"
HARDWARE="ASUS.R540S"

LINUX_VERSION="4.14"
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
	cat /boot/config-$(uname -r) \
		| sed 's|=m|=n|' \
		| sed 's|CONFIG_ACPI_AC=n|CONFIG_ACPI_AC=m|' \
		| sed 's|CONFIG_ACPI_BATTERY=n|CONFIG_ACPI_BATTERY=m|' \
		| sed 's|CONFIG_ACPI_BUTTON=n|CONFIG_ACPI_BUTTON=m|' \
		| sed 's|CONFIG_ACPI_FAN=n|CONFIG_ACPI_FAN=m|' \
		| sed 's|CONFIG_ACPI_THERMAL=n|CONFIG_ACPI_THERMAL=m|' \
		| sed 's|CONFIG_ACPI_VIDEO=n|CONFIG_ACPI_VIDEO=m|' \
		| sed 's|CONFIG_ACPI_WMI=n|CONFIG_ACPI_WMI=m|' \
		| sed 's|CONFIG_ASUS_NB_WMI=n|CONFIG_ASUS_NB_WMI=m|' \
		| sed 's|CONFIG_ASUS_WIRELESS=n|CONFIG_ASUS_WIRELESS=m|' \
		| sed 's|CONFIG_ASUS_WMI=n|CONFIG_ASUS_WMI=m|' \
		| sed 's|CONFIG_ATA=n|CONFIG_ATA=m|' \
		| sed 's|CONFIG_ATH9K_COMMON=n|CONFIG_ATH9K_COMMON=m|' \
		| sed 's|CONFIG_ATH9K_HW=n|CONFIG_ATH9K_HW=m|' \
		| sed 's|CONFIG_ATH9K=n|CONFIG_ATH9K=m|' \
		| sed 's|CONFIG_ATH_COMMON=n|CONFIG_ATH_COMMON=m|' \
		| sed 's|CONFIG_AUTOFS4_FS=n|CONFIG_AUTOFS4_FS=m|' \
		| sed 's|CONFIG_BINFMT_MISC=n|CONFIG_BINFMT_MISC=m|' \
		| sed 's|CONFIG_BLK_DEV_DM=n|CONFIG_BLK_DEV_DM=m|' \
		| sed 's|CONFIG_BLK_DEV_LOOP=n|CONFIG_BLK_DEV_LOOP=m|' \
		| sed 's|CONFIG_BLK_DEV_SD=n|CONFIG_BLK_DEV_SD=m|' \
		| sed 's|CONFIG_BLK_DEV_SR=n|CONFIG_BLK_DEV_SR=m|' \
		| sed 's|CONFIG_CFG80211=n|CONFIG_CFG80211=m|' \
		| sed 's|CONFIG_CHR_DEV_SG=n|CONFIG_CHR_DEV_SG=m|' \
		| sed 's|CONFIG_CRC16=n|CONFIG_CRC16=m|' \
		| sed 's|CONFIG_CRYPTO_AES_NI_INTEL=n|CONFIG_CRYPTO_AES_NI_INTEL=m|' \
		| sed 's|CONFIG_CRYPTO_AES_X86_64=n|CONFIG_CRYPTO_AES_X86_64=m|' \
		| sed 's|CONFIG_CRYPTO_ANSI_CPRNG=n|CONFIG_CRYPTO_ANSI_CPRNG=m|' \
		| sed 's|CONFIG_CRYPTO_ARC4=n|CONFIG_CRYPTO_ARC4=m|' \
		| sed 's|CONFIG_CRYPTO_CCM=n|CONFIG_CRYPTO_CCM=m|' \
		| sed 's|CONFIG_CRYPTO_CRC32C_INTEL=n|CONFIG_CRYPTO_CRC32C_INTEL=m|' \
		| sed 's|CONFIG_CRYPTO_CRC32C=n|CONFIG_CRYPTO_CRC32C=m|' \
		| sed 's|CONFIG_CRYPTO_CRC32=n|CONFIG_CRYPTO_CRC32=m|' \
		| sed 's|CONFIG_CRYPTO_CRC32_PCLMUL=n|CONFIG_CRYPTO_CRC32_PCLMUL=m|' \
		| sed 's|CONFIG_CRYPTO_CRCT10DIF_PCLMUL=n|CONFIG_CRYPTO_CRCT10DIF_PCLMUL=m|' \
		| sed 's|CONFIG_CRYPTO_CRYPTD=n|CONFIG_CRYPTO_CRYPTD=m|' \
		| sed 's|CONFIG_CRYPTO_CTR=n|CONFIG_CRYPTO_CTR=m|' \
		| sed 's|CONFIG_CRYPTO_DRBG=n|CONFIG_CRYPTO_DRBG=m|' \
		| sed 's|CONFIG_CRYPTO_ECB=n|CONFIG_CRYPTO_ECB=m|' \
		| sed 's|CONFIG_CRYPTO_ECDH=n|CONFIG_CRYPTO_ECDH=m|' \
		| sed 's|CONFIG_CRYPTO_GHASH_CLMUL_NI_INTEL=n|CONFIG_CRYPTO_GHASH_CLMUL_NI_INTEL=m|' \
		| sed 's|CONFIG_CRYPTO_GLUE_HELPER_X86=n|CONFIG_CRYPTO_GLUE_HELPER_X86=m|' \
		| sed 's|CONFIG_CRYPTO_SIMD=n|CONFIG_CRYPTO_SIMD=m|' \
		| sed 's|CONFIG_DRM_I915=n|CONFIG_DRM_I915=m|' \
		| sed 's|CONFIG_DRM_KMS_HELPER=n|CONFIG_DRM_KMS_HELPER=m|' \
		| sed 's|CONFIG_DRM=n|CONFIG_DRM=m|' \
		| sed 's|CONFIG_DW_DMAC_CORE=n|CONFIG_DW_DMAC_CORE=m|' \
		| sed 's|CONFIG_DW_DMAC=n|CONFIG_DW_DMAC=m|' \
		| sed 's|CONFIG_EFIVAR_FS=n|CONFIG_EFIVAR_FS=m|' \
		| sed 's|CONFIG_EFI_VARS=n|CONFIG_EFI_VARS=m|' \
		| sed 's|CONFIG_EFI_VARS_PSTORE=n|CONFIG_EFI_VARS_PSTORE=m|' \
		| sed 's|CONFIG_EXT4_FS=n|CONFIG_EXT4_FS=m|' \
		| sed 's|CONFIG_FAT_FS=n|CONFIG_FAT_FS=m|' \
		| sed 's|CONFIG_FS_ENCRYPTION=n|CONFIG_FS_ENCRYPTION=m|' \
		| sed 's|CONFIG_FS_MBCACHE=n|CONFIG_FS_MBCACHE=m|' \
		| sed 's|CONFIG_FUSE_FS=n|CONFIG_FUSE_FS=m|' \
		| sed 's|CONFIG_HID_DRAGONRISE=n|CONFIG_HID_DRAGONRISE=m|' \
		| sed 's|CONFIG_HID_GENERIC=n|CONFIG_HID_GENERIC=m|' \
		| sed 's|CONFIG_HID_LOGITECH=n|CONFIG_HID_LOGITECH=m|' \
		| sed 's|CONFIG_HID=n|CONFIG_HID=m|' \
		| sed 's|CONFIG_HID_SONY=n|CONFIG_HID_SONY=m|' \
		| sed 's|CONFIG_HOTPLUG_PCI_SHPC=n|CONFIG_HOTPLUG_PCI_SHPC=m|' \
		| sed 's|CONFIG_I2C_ALGOBIT=n|CONFIG_I2C_ALGOBIT=m|' \
		| sed 's|CONFIG_I2C_DESIGNWARE_CORE=n|CONFIG_I2C_DESIGNWARE_CORE=m|' \
		| sed 's|CONFIG_I2C_DESIGNWARE_PLATFORM=n|CONFIG_I2C_DESIGNWARE_PLATFORM=m|' \
		| sed 's|CONFIG_I2C_HID=n|CONFIG_I2C_HID=m|' \
		| sed 's|CONFIG_I2C_I801=n|CONFIG_I2C_I801=m|' \
		| sed 's|CONFIG_INPUT_EVDEV=n|CONFIG_INPUT_EVDEV=m|' \
		| sed 's|CONFIG_INPUT_FF_MEMLESS=n|CONFIG_INPUT_FF_MEMLESS=m|' \
		| sed 's|CONFIG_INPUT_JOYDEV=n|CONFIG_INPUT_JOYDEV=m|' \
		| sed 's|CONFIG_INPUT_PCSPKR=n|CONFIG_INPUT_PCSPKR=m|' \
		| sed 's|CONFIG_INPUT_SPARSEKMAP=n|CONFIG_INPUT_SPARSEKMAP=m|' \
		| sed 's|CONFIG_INT3406_THERMAL=n|CONFIG_INT3406_THERMAL=m|' \
		| sed 's|CONFIG_INT340X_THERMAL=n|CONFIG_INT340X_THERMAL=m|' \
		| sed 's|CONFIG_INTEL_POWERCLAMP=n|CONFIG_INTEL_POWERCLAMP=m|' \
		| sed 's|CONFIG_INTEL_RAPL=n|CONFIG_INTEL_RAPL=m|' \
		| sed 's|CONFIG_INTEL_SOC_DTS_IOSF_CORE=n|CONFIG_INTEL_SOC_DTS_IOSF_CORE=m|' \
		| sed 's|CONFIG_IP6_NF_FILTER=n|CONFIG_IP6_NF_FILTER=m|' \
		| sed 's|CONFIG_IP6_NF_IPTABLES=n|CONFIG_IP6_NF_IPTABLES=m|' \
		| sed 's|CONFIG_IP6_NF_MANGLE=n|CONFIG_IP6_NF_MANGLE=m|' \
		| sed 's|CONFIG_IP6_NF_MATCH_RT=n|CONFIG_IP6_NF_MATCH_RT=m|' \
		| sed 's|CONFIG_IP6_NF_NAT=n|CONFIG_IP6_NF_NAT=m|' \
		| sed 's|CONFIG_IP_NF_FILTER=n|CONFIG_IP_NF_FILTER=m|' \
		| sed 's|CONFIG_IP_NF_IPTABLES=n|CONFIG_IP_NF_IPTABLES=m|' \
		| sed 's|CONFIG_IP_NF_MANGLE=n|CONFIG_IP_NF_MANGLE=m|' \
		| sed 's|CONFIG_IP_NF_NAT=n|CONFIG_IP_NF_NAT=m|' \
		| sed 's|CONFIG_IRQ_BYPASS_MANAGER=n|CONFIG_IRQ_BYPASS_MANAGER=m|' \
		| sed 's|CONFIG_ISO9660_FS=n|CONFIG_ISO9660_FS=m|' \
		| sed 's|CONFIG_ITCO_WDT=n|CONFIG_ITCO_WDT=m|' \
		| sed 's|CONFIG_JBD2=n|CONFIG_JBD2=m|' \
		| sed 's|CONFIG_KVM_INTEL=n|CONFIG_KVM_INTEL=m|' \
		| sed 's|CONFIG_KVM=n|CONFIG_KVM=m|' \
		| sed 's|CONFIG_LPC_ICH=n|CONFIG_LPC_ICH=m|' \
		| sed 's|CONFIG_MAC80211=n|CONFIG_MAC80211=m|' \
		| sed 's|CONFIG_MEDIA_SUPPORT=n|CONFIG_MEDIA_SUPPORT=m|' \
		| sed 's|CONFIG_MFD_CORE=n|CONFIG_MFD_CORE=m|' \
		| sed 's|CONFIG_MII=n|CONFIG_MII=m|' \
		| sed 's|CONFIG_MMC=n|CONFIG_MMC=m|' \
		| sed 's|CONFIG_MMC_SDHCI_ACPI=n|CONFIG_MMC_SDHCI_ACPI=m|' \
		| sed 's|CONFIG_MMC_SDHCI=n|CONFIG_MMC_SDHCI=m|' \
		| sed 's|CONFIG_MOUSE_ELAN_I2C=n|CONFIG_MOUSE_ELAN_I2C=m|' \
		| sed 's|CONFIG_MSDOS_FS=n|CONFIG_MSDOS_FS=m|' \
		| sed 's|CONFIG_NETFILTER_XTABLES=n|CONFIG_NETFILTER_XTABLES=m|' \
		| sed 's|CONFIG_NETFILTER_XT_MATCH_CONNTRACK=n|CONFIG_NETFILTER_XT_MATCH_CONNTRACK=m|' \
		| sed 's|CONFIG_NF_CONNTRACK_FTP=n|CONFIG_NF_CONNTRACK_FTP=m|' \
		| sed 's|CONFIG_NF_CONNTRACK_IPV4=n|CONFIG_NF_CONNTRACK_IPV4=m|' \
		| sed 's|CONFIG_NF_CONNTRACK_IPV6=n|CONFIG_NF_CONNTRACK_IPV6=m|' \
		| sed 's|CONFIG_NF_CONNTRACK_IRC=n|CONFIG_NF_CONNTRACK_IRC=m|' \
		| sed 's|CONFIG_NF_CONNTRACK=n|CONFIG_NF_CONNTRACK=m|' \
		| sed 's|CONFIG_NF_CONNTRACK_PPTP=n|CONFIG_NF_CONNTRACK_PPTP=m|' \
		| sed 's|CONFIG_NF_CONNTRACK_TFTP=n|CONFIG_NF_CONNTRACK_TFTP=m|' \
		| sed 's|CONFIG_NF_DEFRAG_IPV4=n|CONFIG_NF_DEFRAG_IPV4=m|' \
		| sed 's|CONFIG_NF_DEFRAG_IPV6=n|CONFIG_NF_DEFRAG_IPV6=m|' \
		| sed 's|CONFIG_NF_NAT_FTP=n|CONFIG_NF_NAT_FTP=m|' \
		| sed 's|CONFIG_NF_NAT_IPV4=n|CONFIG_NF_NAT_IPV4=m|' \
		| sed 's|CONFIG_NF_NAT_IPV6=n|CONFIG_NF_NAT_IPV6=m|' \
		| sed 's|CONFIG_NF_NAT_IRC=n|CONFIG_NF_NAT_IRC=m|' \
		| sed 's|CONFIG_NF_NAT=n|CONFIG_NF_NAT=m|' \
		| sed 's|CONFIG_NF_NAT_PPTP=n|CONFIG_NF_NAT_PPTP=m|' \
		| sed 's|CONFIG_NF_NAT_TFTP=n|CONFIG_NF_NAT_TFTP=m|' \
		| sed 's|CONFIG_NLS_ASCII=n|CONFIG_NLS_ASCII=m|' \
		| sed 's|CONFIG_NLS_CODEPAGE_437=n|CONFIG_NLS_CODEPAGE_437=m|' \
		| sed 's|CONFIG_NTFS_FS=n|CONFIG_NTFS_FS=m|' \
		| sed 's|CONFIG_OVERLAY_FS=n|CONFIG_OVERLAY_FS=m|' \
		| sed 's|CONFIG_PARPORT=n|CONFIG_PARPORT=m|' \
		| sed 's|CONFIG_PARPORT_PC=n|CONFIG_PARPORT_PC=m|' \
		| sed 's|CONFIG_PERF_EVENTS_INTEL_CSTATE=n|CONFIG_PERF_EVENTS_INTEL_CSTATE=m|' \
		| sed 's|CONFIG_PERF_EVENTS_INTEL_RAPL=n|CONFIG_PERF_EVENTS_INTEL_RAPL=m|' \
		| sed 's|CONFIG_PERF_EVENTS_INTEL_UNCORE=n|CONFIG_PERF_EVENTS_INTEL_UNCORE=m|' \
		| sed 's|CONFIG_PPDEV=n|CONFIG_PPDEV=m|' \
		| sed 's|CONFIG_R8169=n|CONFIG_R8169=m|' \
		| sed 's|CONFIG_RFKILL=n|CONFIG_RFKILL=m|' \
		| sed 's|CONFIG_SATA_ACARD_AHCI=n|CONFIG_SATA_ACARD_AHCI=m|' \
		| sed 's|CONFIG_SATA_AHCI=n|CONFIG_SATA_AHCI=m|' \
		| sed 's|CONFIG_SCSI_MOD=n|CONFIG_SCSI_MOD=m|' \
		| sed 's|CONFIG_SENSORS_CORETEMP=n|CONFIG_SENSORS_CORETEMP=m|' \
		| sed 's|CONFIG_SERIO_RAW=n|CONFIG_SERIO_RAW=m|' \
		| sed 's|CONFIG_SND_COMPRESS_OFFLOAD=n|CONFIG_SND_COMPRESS_OFFLOAD=m|' \
		| sed 's|CONFIG_SND_HDA_CODEC_HDMI=n|CONFIG_SND_HDA_CODEC_HDMI=m|' \
		| sed 's|CONFIG_SND_HDA_CODEC_REALTEK=n|CONFIG_SND_HDA_CODEC_REALTEK=m|' \
		| sed 's|CONFIG_SND_HDA_CORE=n|CONFIG_SND_HDA_CORE=m|' \
		| sed 's|CONFIG_SND_HDA_GENERIC=n|CONFIG_SND_HDA_GENERIC=m|' \
		| sed 's|CONFIG_SND_HDA_INTEL=n|CONFIG_SND_HDA_INTEL=m|' \
		| sed 's|CONFIG_SND_HDA=n|CONFIG_SND_HDA=m|' \
		| sed 's|CONFIG_SND_HWDEP=n|CONFIG_SND_HWDEP=m|' \
		| sed 's|CONFIG_SND=n|CONFIG_SND=m|' \
		| sed 's|CONFIG_SND_PCM=n|CONFIG_SND_PCM=m|' \
		| sed 's|CONFIG_SND_SEQ_DEVICE=n|CONFIG_SND_SEQ_DEVICE=m|' \
		| sed 's|CONFIG_SND_SOC_INTEL_SST_ACPI=n|CONFIG_SND_SOC_INTEL_SST_ACPI=m|' \
		| sed 's|CONFIG_SND_SOC_INTEL_SST_MATCH=n|CONFIG_SND_SOC_INTEL_SST_MATCH=m|' \
		| sed 's|CONFIG_SND_SOC_INTEL_SST=n|CONFIG_SND_SOC_INTEL_SST=m|' \
		| sed 's|CONFIG_SND_SOC=n|CONFIG_SND_SOC=m|' \
		| sed 's|CONFIG_SND_SST_ATOM_HIFI2_PLATFORM=n|CONFIG_SND_SST_ATOM_HIFI2_PLATFORM=m|' \
		| sed 's|CONFIG_SND_TIMER=n|CONFIG_SND_TIMER=m|' \
		| sed 's|CONFIG_SND_USB_AUDIO=n|CONFIG_SND_USB_AUDIO=m|' \
		| sed 's|CONFIG_SOUND=n|CONFIG_SOUND=m|' \
		| sed 's|CONFIG_SPI_PXA2XX=n|CONFIG_SPI_PXA2XX=m|' \
		| sed 's|CONFIG_SQUASHFS=n|CONFIG_SQUASHFS=m|' \
		| sed 's|CONFIG_TCG_TPM=n|CONFIG_TCG_TPM=m|' \
		| sed 's|CONFIG_TUN=n|CONFIG_TUN=m|' \
		| sed 's|CONFIG_USB_COMMON=n|CONFIG_USB_COMMON=m|' \
		| sed 's|CONFIG_USB_HID=n|CONFIG_USB_HID=m|' \
		| sed 's|CONFIG_USB=n|CONFIG_USB=m|' \
		| sed 's|CONFIG_USB_NET_CDCETHER=n|CONFIG_USB_NET_CDCETHER=m|' \
		| sed 's|CONFIG_USB_STORAGE=n|CONFIG_USB_STORAGE=m|' \
		| sed 's|CONFIG_USB_UAS=n|CONFIG_USB_UAS=m|' \
		| sed 's|CONFIG_USB_XHCI_HCD=n|CONFIG_USB_XHCI_HCD=m|' \
		| sed 's|CONFIG_USB_XHCI_PCI=n|CONFIG_USB_XHCI_PCI=m|' \
		| sed 's|CONFIG_VFAT_FS=n|CONFIG_VFAT_FS=m|' \
		> .config
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
	config_kernel
	make_kernel
)

# bluetooth
#		| sed 's|CONFIG_BT_ATH3K=n|CONFIG_BT_ATH3K=m|' \
#		| sed 's|CONFIG_BT_BCM=n|CONFIG_BT_BCM=m|' \
#		| sed 's|CONFIG_BT_BNEP=n|CONFIG_BT_BNEP=m|' \
#		| sed 's|CONFIG_BT_HCIBTUSB=n|CONFIG_BT_HCIBTUSB=m|' \
#		| sed 's|CONFIG_BT_INTEL=n|CONFIG_BT_INTEL=m|' \
#		| sed 's|CONFIG_BT=n|CONFIG_BT=m|' \
#		| sed 's|CONFIG_BT_RTL=n|CONFIG_BT_RTL=m|' \
