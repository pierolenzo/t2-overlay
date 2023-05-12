# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="4"

inherit kernel-2
detect_version
detect_arch

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
HOMEPAGE="https://dev.gentoo.org/~mpagano/genpatches"
IUSE="experimental"

MY_T2_COMMIT="0235dd75fba03f81295701c1b18e5b7888d2a3e7"
DESCRIPTION="Full sources including the Gentoo patchset for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}
	https://github.com/t2linux/linux-t2-patches/archive/${MY_T2_COMMIT}.tar.gz -> linux-t2-patches-${MY_T2_COMMIT}.tar.gz"

src_unpack() {
	unpack "linux-t2-patches-${MY_T2_COMMIT}.tar.gz"
	kernel-2_src_unpack
}

src_prepare() {
	eapply "${WORKDIR}/linux-t2-patches-${MY_T2_COMMIT}"/*.patch
	kernel-2_src_prepare
}

pkg_postinst() {
	kernel-2_pkg_postinst
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
