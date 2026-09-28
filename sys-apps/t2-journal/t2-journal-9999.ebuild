# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo git-r3 linux-info

DESCRIPTION="Apple T2 bridgeOS and Linux journal reader (live git)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/t2-services/t2-journal"

LICENSE="GPL-3+ Apache-2.0 BSD MIT Unicode-3.0"
SLOT="0"
KEYWORDS=""

RDEPEND="
	|| (
		sys-apps/systemd
		sys-apps/systemd-utils
	)
"
DEPEND=""
BDEPEND="
	virtual/pkgconfig
"

QA_FLAGS_IGNORED="usr/bin/t2journal"

# Kernel configuration requirements for Apple T2 CDC-NCM link
CONFIG_CHECK="~USB_NET_CDC_NCM ~USB_USBNET ~IPV6"
ERROR_USB_NET_CDC_NCM="CONFIG_USB_NET_CDC_NCM is required to communicate with Apple T2 USB Ethernet (05ac:8233)."
ERROR_USB_USBNET="CONFIG_USB_USBNET is required for USB networking drivers."
ERROR_IPV6="CONFIG_IPV6 is required to communicate with the T2 chip over link-local IPv6."

pkg_pretend() {
	linux-info_pkg_setup
}

pkg_setup() {
	rust_pkg_setup
	linux-info_pkg_setup
}

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_compile() {
	cargo_src_compile
}

src_test() {
	cargo_src_test
}

src_install() {
	cargo_src_install --path ./
	dodoc README.md
}
