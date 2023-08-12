# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ADITYAGARG8_APPLE_TOUCHBAR_DRV_COMMIT="ff9ca3da6ad6b7b820c3685c515ad4a61c6455b8"
inherit linux-mod-r1

DESCRIPTION="Apple iBridge devices support (Touchbar/ALS) for MacBook Pro 2018 and onward."
HOMEPAGE="https://t2linux.org"
SRC_URI="https://github.com/AdityaGarg8/apple-touchbar-drv/archive/${ADITYAGARG8_APPLE_TOUCHBAR_DRV_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${PN}-drv-${ADITYAGARG8_APPLE_TOUCHBAR_DRV_COMMIT}"

RDEPEND="
	!sys-kernel/t2gentoo-kernel
	!sys-kernel/t2gentoo-sources
"

src_compile() {
	local modlist=(
		apple-ibridge
		apple-touchbar
		hid-apple-magic-backlight
	)

	linux-mod-r1_src_compile
}
