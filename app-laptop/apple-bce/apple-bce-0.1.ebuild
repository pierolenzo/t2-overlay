# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit dist-kernel-utils linux-mod-r1

DESCRIPTION="Apple BCE (Buffer Copy Engine) and associated subsystems drivers for T2 Macs"
HOMEPAGE="https://t2linux.org"
SRC_URI="https://codeberg.org/vimproved/apple-bce/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${PN}"

RDEPEND="
	!sys-kernel/t2gentoo-kernel
	!sys-kernel/t2gentoo-sources
"

src_compile() {
	local modlist=( apple-bce )

	export KERNELRELEASE=${KV_FULL}
	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install
	insinto "/etc/dracut.conf.d"
	doins "${FILESDIR}/apple-bce.conf"
}

pkg_postinst() {
	linux-mod-r1_pkg_postinst

	if [[ -z ${ROOT} ]] && use dist-kernel; then
		dist-kernel_reinstall_initramfs "${KV_DIR}" "${KV_FULL}"
	fi
}
