# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	adler2@2.0.1
	aho-corasick@1.1.5
	android_system_properties@0.1.6
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	anyhow@1.0.104
	autocfg@1.5.1
	base64@0.22.1
	base64@0.23.1
	bitflags@2.13.1
	bumpalo@3.20.3
	byteorder@1.5.0
	cc@1.4.5
	cfg-if@1.0.4
	chrono@0.4.45
	clap@4.6.6
	clap_builder@4.6.6
	clap_derive@4.6.4
	clap_lex@1.1.0
	colorchoice@1.0.5
	core-foundation-sys@0.8.7
	crc32fast@1.5.1
	deranged@0.5.8
	equivalent@1.0.2
	errno@0.3.14
	fastrand@2.5.0
	filetime@0.2.29
	find-msvc-tools@0.1.12
	flate2@1.1.10
	futures-core@0.3.33
	futures-task@0.3.33
	futures-util@0.3.33
	getrandom@0.4.3
	hashbrown@0.17.1
	heck@0.5.0
	iana-time-zone-haiku@0.1.2
	iana-time-zone@0.1.65
	indexmap@2.14.1
	is_terminal_polyfill@1.70.2
	itoa@1.0.18
	js-sys@0.3.104
	libc@0.2.189
	linux-raw-sys@0.12.1
	log@0.4.34
	lz4_flex@0.14.0
	memchr@2.8.3
	miniz_oxide@0.9.1
	nom@8.0.0
	num-conv@0.2.2
	num-traits@0.2.19
	once_cell@1.21.4
	once_cell_polyfill@1.70.2
	pin-project-lite@0.2.17
	plist@1.10.0
	powerfmt@0.2.0
	proc-macro2@1.0.107
	quick-xml@0.41.0
	quote@1.0.47
	r-efi@6.0.0
	regex-automata@0.4.18
	regex-syntax@0.8.11
	regex@1.13.1
	rustix@1.1.4
	rustversion@1.0.23
	same-file@1.0.6
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.151
	shlex@2.0.1
	simd-adler32@0.3.10
	slab@0.4.12
	socket2@0.6.5
	strsim@0.11.1
	sunlight@0.1.5
	syn@2.0.119
	syn@3.0.4
	tar@0.4.46
	tempfile@3.27.0
	time-core@0.1.9
	time-macros@0.2.32
	time@0.3.55
	twox-hash@2.1.4
	unicode-ident@1.0.24
	utf8parse@0.2.2
	uuid@1.26.0
	walkdir@2.5.0
	wasm-bindgen-macro-support@0.2.127
	wasm-bindgen-macro@0.2.127
	wasm-bindgen-shared@0.2.127
	wasm-bindgen@0.2.127
	winapi-util@0.1.11
	windows-core@0.62.2
	windows-implement@0.60.2
	windows-interface@0.59.3
	windows-link@0.2.1
	windows-result@0.4.1
	windows-strings@0.5.1
	windows-sys@0.61.2
	xattr@1.6.1
	zlib-rs@0.6.7
	zmij@1.0.23
"

inherit cargo linux-info

DESCRIPTION="Apple T2 bridgeOS and Linux journal reader"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"

# Snapshot commit from kaiT2en-Fedora repository containing t2-journal
COMMIT="c8601fac525c853eb38a296a321989880375b481"
SRC_URI="
	https://github.com/kaiT2en/KaiT2en-Fedora/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/KaiT2en-Fedora-${COMMIT}/t2-services/t2-journal"

LICENSE="GPL-3+ Apache-2.0 BSD MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"

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
