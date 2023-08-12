# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
KERNEL_PV="6.4.10"
KERNEL_P="linux-${KERNEL_PV%.*}"
GENPATCHES_P=genpatches-${KERNEL_PV%.*}-$(( ${KERNEL_PV##*.} + 2 ))
T2LINUX_LINUX_T2_PATCHES_COMMIT="c908e506346681139a844d41c40b295cfad17ea8"
inherit linux-mod-r1

DESCRIPTION="Version of the applesmc driver with T2 specific patches."
HOMEPAGE="https://t2linux.org/"
SRC_URI="https://github.com/t2linux/linux-t2-patches/archive/${T2LINUX_LINUX_T2_PATCHES_COMMIT}.tar.gz -> linux-t2-patches-${T2LINUX_LINUX_T2_PATCHES_COMMIT}.tar.gz
	https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_PV%%.*}.x/${KERNEL_P}.tar.xz
	https://dev.gentoo.org/~mpagano/dist/genpatches/${GENPATCHES_P}.base.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${KERNEL_P}/drivers/hwmon"

RDEPEND="
	!sys-kernel/t2gentoo-kernel
	!sys-kernel/t2gentoo-sources
"

src_prepare() {
	pushd "${WORKDIR}/${KERNEL_P}" > /dev/null 2>&1
	eapply "${WORKDIR}/"*.patch
	eapply "${WORKDIR}/linux-t2-patches-${T2LINUX_LINUX_T2_PATCHES_COMMIT}/"*.patch
	popd > /dev/null 2>&1
	# questionable makefile thing
	echo "
obj-m += applesmc.o

KVERSION := \$(KERNELRELEASE)
ifeq (\$(origin KERNELRELEASE), undefined)
KVERSION := \$(shell uname -r)
endif
KDIR := /lib/modules/\$(KVERSION)/build
PWD := \$(shell pwd)

all:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) modules

clean:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) clean

install:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) modules_install2" > "${S}/Makefile"
	default
}

src_compile() {
	local modlist=( applesmc )

	linux-mod-r1_src_compile
}
