# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit linux-mod-r1

DESCRIPTION="applesmc kernel module with additional patches for t2 macs"
HOMEPAGE="https://t2linux.org"
SRC_URI="https://codeberg.org/vimproved/applesmc-t2/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${PN}"

RDEPEND="
	!sys-kernel/t2gentoo-kernel
	!sys-kernel/t2gentoo-sources
"

src_compile() {
	local modlist=( applesmc=updates )

	linux-mod-r1_src_compile
}
