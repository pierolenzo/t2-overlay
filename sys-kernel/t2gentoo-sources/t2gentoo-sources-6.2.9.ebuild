# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_SECURITY_UNSUPPORTED="1"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="11"

inherit kernel-2
detect_version
detect_arch

KEYWORDS="~amd64"
HOMEPAGE="https://wiki.t2linux.org/"
IUSE="experimental"

DESCRIPTION="Linux kernel sources including patches for T2 MacBooks and genpatches"
T2_COMMIT="3a43f2fa1c4afec28f1bffe2aa13e3f4366ecce1"
T2_URI="https://github.com/t2linux/linux-t2-patches/archive/${T2_COMMIT}.tar.gz -> linux-t2-patches-${T2_COMMIT}.tar.gz"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI} ${T2_URI}"

src_unpack() {
	unpack "linux-t2-patches-${T2_COMMIT}.tar.gz"
	kernel-2_src_unpack
}

src_prepare() {
	eapply "${WORKDIR}"/"linux-t2-patches-${T2_COMMIT}"/*.patch
	rm -rf "${WORKDIR}/linux-t2-patches-${T2_COMMIT}"
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
