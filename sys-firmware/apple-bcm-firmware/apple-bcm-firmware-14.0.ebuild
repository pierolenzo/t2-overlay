# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit unpacker

DESCRIPTION="WiFi firmware for Apple's T2 MacBooks."
HOMEPAGE="https://wiki.t2linux.org/guides/wifi-bluetooth/"
SRC_URI="https://mirror.funami.tech/arch-mact2/os/x86_64/${P}-1-any.pkg.tar.zst"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
BRCMFMAC_CARDS_IUSE="
	hawaii ekans hanauma kahana kauai lanai maui midway nihau sid bali borneo hanauma kahana kure sid trinidad fiji
	formosa tahiti atlantisb capri honshu santorini shikoku kyushu hokkaido madagascar maldives okinawa
"

cards=( ${BRCMFMAC_CARDS_IUSE} )
IUSE+=" ${cards[@]/#/brcmfmac_cards_}"

BDEPEND="
	app-arch/zstd
"

S="${WORKDIR}"

src_unpack() {
	unpacker_src_unpack
}

src_install() {
	insinto /lib/firmware/brcm/
	for card in ${BRCMFMAC_CARDS}; do
		doins "${WORKDIR}/usr/lib/firmware/brcm/brcmfmac43"*"-pcie.apple,${card}"*
	done
}
