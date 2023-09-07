# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="3"
LINUX_T2_PATCHES_VER="46dd873d1d9d12b26916790045008a91a95d0c11"

inherit kernel-2
detect_version
detect_arch

KEYWORDS="~amd64"
HOMEPAGE="https://wiki.t2linux.org/"
IUSE="experimental"

DESCRIPTION="Full sources including the Gentoo patchset for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
SRC_URI="
	${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}
	https://github.com/t2linux/linux-t2-patches/archive/${LINUX_T2_PATCHES_VER}.tar.gz
		-> linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz
"

src_unpack() {
	unpack "linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz"
	kernel-2_src_unpack
}

src_prepare() {
	 kernel-2_src_prepare
	 eapply "${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}"/*.patch
}

pkg_postinst() {
	kernel-2_pkg_postinst
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
