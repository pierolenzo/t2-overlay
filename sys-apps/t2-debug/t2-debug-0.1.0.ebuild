# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	aho-corasick@1.1.5
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	anyhow@1.0.104
	autocfg@1.5.1
	base64@0.23.1
	bitflags@2.13.2
	bumpalo@3.20.3
	cairo-rs@0.20.12
	cairo-sys-rs@0.20.10
	cfg-expr@0.20.10
	cfg-if@1.0.5
	clap@4.6.7
	clap_builder@4.6.7
	clap_derive@4.6.7
	clap_lex@1.1.1
	colorchoice@1.0.5
	deranged@0.5.9
	equivalent@1.0.3
	field-offset@0.3.6
	futures-channel@0.3.34
	futures-core@0.3.34
	futures-executor@0.3.34
	futures-io@0.3.34
	futures-macro@0.3.34
	futures-task@0.3.34
	futures-util@0.3.34
	gdk-pixbuf-sys@0.20.10
	gdk-pixbuf@0.20.10
	gdk4-sys@0.9.6
	gdk4@0.9.6
	getrandom@0.4.3
	gio-sys@0.20.10
	gio@0.20.12
	glib-macros@0.20.12
	glib-sys@0.20.10
	glib@0.20.12
	gobject-sys@0.20.10
	graphene-rs@0.20.10
	graphene-sys@0.20.10
	gsk4-sys@0.9.6
	gsk4@0.9.6
	gtk4-macros@0.9.5
	gtk4-sys@0.9.6
	gtk4@0.9.7
	hashbrown@0.17.1
	heck@0.5.0
	indexmap@2.14.2
	is_terminal_polyfill@1.70.2
	itoa@1.0.18
	js-sys@0.3.106
	libadwaita-sys@0.7.2
	libadwaita@0.7.2
	libc@0.2.191
	memchr@2.8.3
	memoffset@0.9.1
	num-conv@0.2.2
	once_cell@1.21.4
	once_cell_polyfill@1.70.2
	pango-sys@0.20.10
	pango@0.20.12
	pin-project-lite@0.2.17
	pkg-config@0.3.34
	plist@1.10.2
	powerfmt@0.2.1
	proc-macro-crate@3.5.0
	proc-macro2@1.0.107
	quick-xml@0.42.0
	quote@1.0.47
	r-efi@6.0.0
	regex-automata@0.4.18
	regex-syntax@0.8.11
	regex@1.13.1
	rustc_version@0.4.1
	rustversion@1.0.23
	semver@1.0.28
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.154
	serde_spanned@1.1.2
	slab@0.4.12
	smallvec@1.16.3
	socket2@0.6.5
	strsim@0.11.1
	syn@2.0.119
	syn@3.0.9
	system-deps@7.0.8
	target-lexicon@0.13.5
	time-core@0.1.9
	time-macros@0.2.32
	time@0.3.55
	toml@1.1.8+spec-1.1.0
	toml_datetime@1.1.2+spec-1.1.0
	toml_edit@0.25.17+spec-1.1.0
	toml_parser@1.1.5+spec-1.1.0
	toml_writer@1.1.3+spec-1.1.0
	unicode-ident@1.0.27
	utf8parse@0.2.2
	uuid@1.28.0
	version-compare@0.2.1
	wasm-bindgen-macro-support@0.2.129
	wasm-bindgen-macro@0.2.129
	wasm-bindgen-shared@0.2.129
	wasm-bindgen@0.2.129
	windows-link@0.2.1
	windows-sys@0.59.0
	windows-sys@0.61.2
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.52.6
	winnow@1.0.4
	zmij@1.0.23
"

inherit cargo linux-info xdg

DESCRIPTION="Live Apple T2 (bridgeOS) debugger over the Instruments dtservicehub"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"

# Snapshot commit from KaiT2en-Fedora repository containing apps/t2-debug
COMMIT="d63421ba1b9a59b681a29245aaa0fa03d0d59cbe"
SRC_URI="
	https://github.com/kaiT2en/KaiT2en-Fedora/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/KaiT2en-Fedora-${COMMIT}/apps/t2-debug"

LICENSE="GPL-3+ Apache-2.0-with-LLVM-exceptions MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"
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
