# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
T2LINUX_APPLE_BCE_DRV_COMMIT="83116fc3e8d8cfc0e5f205e2361d5af56ad642cd"
inherit linux-mod-r1

DESCRIPTION="Apple BCE (Buffer Copy Engine) and associated subsystems drivers for T2 Macs"
HOMEPAGE="https://t2linux.org"
SRC_URI="https://github.com/t2linux/apple-bce-drv/archive/${T2LINUX_APPLE_BCE_DRV_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${PN}-drv-${T2LINUX_APPLE_BCE_DRV_COMMIT}"

RDEPEND="
	!sys-kernel/t2gentoo-kernel
	!sys-kernel/t2gentoo-sources
"

src_compile() {
	local modlist=( apple-bce )

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install
	insinto "/etc/dracut.conf.d"
	doins "${FILESDIR}/apple-bce.conf"
}
