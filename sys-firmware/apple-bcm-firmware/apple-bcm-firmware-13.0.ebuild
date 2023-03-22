# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit unpacker

DESCRIPTION="WiFi firmware for Apple's T2 MacBooks."
HOMEPAGE="https://wiki.t2linux.org/guides/wifi-bluetooth/"
SRC_URI="https://mirror.funami.tech/arch-mact2/os/x86_64/${P}-1-any.pkg.tar.zst"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
IUSE="savedconfig"

BDEPEND="
	app-arch/zstd
"

S="${WORKDIR}"

src_unpack() {
	unpacker_src_unpack
}

src_install() {
	insinto /lib/firmware/
	doins -r "${WORKDIR}/usr/lib/firmware/brcm/"
}
