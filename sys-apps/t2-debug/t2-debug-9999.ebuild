# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo git-r3 linux-info xdg

DESCRIPTION="Live Apple T2 (bridgeOS) debugger over the Instruments dtservicehub (live git)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/apps/t2-debug"

LICENSE="GPL-3+ Apache-2.0-with-LLVM-exceptions MIT Unicode-3.0"
SLOT="0"
KEYWORDS=""
IUSE="+gui"

RDEPEND="
	gui? (
		gui-libs/gtk:4
		gui-libs/libadwaita:1
		dev-libs/glib:2
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	gui? ( dev-libs/glib:2 )
"

QA_FLAGS_IGNORED="usr/bin/t2-debug usr/bin/t2debug"

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

src_prepare() {
	default
	if use gui; then
		sed -i -e 's|/usr/local/bin|/usr/bin|g' org.t2debug.gtk.desktop || die
	fi
}

src_compile() {
	local cargo_args=(
		$(usev !gui --no-default-features)
	)
	cargo_src_compile "${cargo_args[@]}"
}

src_test() {
	local cargo_args=(
		$(usev !gui --no-default-features)
	)
	cargo_src_test "${cargo_args[@]}"
}

src_install() {
	cargo_src_install --path ./

	if use gui; then
		domenu org.t2debug.gtk.desktop
		doicon -s scalable assets/icons/hicolor/scalable/apps/org.t2debug.gtk.svg
	fi

	dodoc README.md
}
