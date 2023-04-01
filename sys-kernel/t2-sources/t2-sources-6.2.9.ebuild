# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_SECURITY_UNSUPPORTED="1"
ETYPE="sources"
inherit kernel-2
detect_version

DESCRIPTION="Linux kernel sources including patches for T2 MacBooks"
HOMEPAGE="https://www.kernel.org"
T2_COMMIT="3a43f2fa1c4afec28f1bffe2aa13e3f4366ecce1"
T2_URI="https://github.com/t2linux/linux-t2-patches/archive/${T2_COMMIT}.tar.gz -> linux-t2-patches-${T2_COMMIT}.tar.gz"
SRC_URI="${KERNEL_URI} ${T2_URI}"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86"

src_unpack() {
	unpack "linux-t2-patches-${T2_COMMIT}.tar.gz"
	kernel-2_src_unpack
}

src_prepare() {
	eapply "${WORKDIR}"/"linux-t2-patches-${T2_COMMIT}"/*.patch
	rm -rf "${WORKDIR}/linux-t2-patches-${T2_COMMIT}"
	kernel-2_src_prepare
}
