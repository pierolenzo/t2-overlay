# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	anyhow@1.0.104
	async-broadcast@0.7.2
	async-channel@2.5.0
	async-executor@1.14.0
	async-io@2.6.0
	async-lock@3.4.2
	async-process@2.5.0
	async-recursion@1.1.1
	async-signal@0.2.14
	async-task@4.7.1
	async-trait@0.1.92
	atomic-waker@1.1.2
	autocfg@1.5.1
	base64@0.23.1
	bitflags@2.13.2
	blocking@1.7.0
	bumpalo@3.20.3
	cfg-if@1.0.4
	concurrent-queue@2.5.0
	crossbeam-utils@0.8.23
	deranged@0.5.8
	endi@1.1.1
	enumflags2@0.7.12
	enumflags2_derive@0.7.12
	equivalent@1.0.2
	errno@0.3.14
	event-listener-strategy@0.5.4
	event-listener@5.4.2
	fastrand@2.5.0
	futures-core@0.3.34
	futures-io@0.3.34
	futures-lite@2.6.1
	futures-task@0.3.34
	futures-util@0.3.34
	getrandom@0.4.3
	hashbrown@0.17.1
	hermit-abi@0.5.3
	hex@0.4.3
	indexmap@2.14.2
	itoa@1.0.18
	js-sys@0.3.105
	libc@0.2.189
	linux-raw-sys@0.12.1
	memchr@2.8.3
	memoffset@0.9.1
	num-conv@0.2.2
	once_cell@1.21.4
	ordered-stream@0.2.0
	parking@2.2.1
	pin-project-lite@0.2.17
	piper@0.2.5
	plist@1.10.1
	polling@3.11.0
	powerfmt@0.2.0
	proc-macro-crate@3.5.0
	proc-macro2@1.0.107
	quick-xml@0.42.0
	quote@1.0.47
	r-efi@6.0.0
	rustix@1.1.4
	rustversion@1.0.23
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.151
	serde_repr@0.1.21
	signal-hook-registry@1.4.8
	slab@0.4.12
	socket2@0.6.5
	syn@2.0.119
	syn@3.0.5
	tempfile@3.27.0
	time-core@0.1.9
	time-macros@0.2.32
	time@0.3.55
	toml_datetime@1.1.1+spec-1.1.0
	toml_edit@0.25.15+spec-1.1.0
	toml_parser@1.1.3+spec-1.1.0
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing@0.1.44
	uds_windows@1.2.1
	unicode-ident@1.0.24
	uuid@1.26.1
	wasm-bindgen-macro-support@0.2.128
	wasm-bindgen-macro@0.2.128
	wasm-bindgen-shared@0.2.128
	wasm-bindgen@0.2.128
	windows-link@0.2.1
	windows-sys@0.61.2
	winnow@1.0.4
	zbus@5.19.0
	zbus_macros@5.19.0
	zbus_names@4.3.4
	zcheapstr@1.1.0
	zmij@1.0.23
	zvariant@5.15.0
	zvariant_derive@5.15.0
	zvariant_utils@4.2.0
"

inherit cargo linux-info multilib systemd

DESCRIPTION="Bridges Apple T2 Touch ID sensor to fprintd via libfprint virtual device"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"

# Snapshot commit from kaiT2en-Fedora repository containing t2-touchid
COMMIT="c8601fa80c1be1b4ffc70d4b4a621bebe3ff558e"
SRC_URI="
	https://github.com/kaiT2en/KaiT2en-Fedora/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/KaiT2en-Fedora-${COMMIT}/t2-services/t2-touchid"

LICENSE="GPL-3+ Apache-2.0 BSD MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="elogind networkmanager systemd"
REQUIRED_USE="?? ( elogind systemd )"

RDEPEND="
	sys-auth/fprintd
	>=sys-auth/libfprint-1.94.0[virtual-drivers(+)]
	net-misc/iputils
	sys-apps/iproute2
	sys-apps/dbus
	elogind? ( sys-auth/elogind )
	systemd? ( sys-apps/systemd )
	networkmanager? ( net-misc/networkmanager )
"
DEPEND=""
BDEPEND="
	virtual/rust
	virtual/pkgconfig
"

# The binary must run on Apple T2 architecture (x86_64)
QA_FLAGS_IGNORED="usr/bin/t2-touchid"

# Kernel configuration requirements for Apple T2 CDC-NCM link
CONFIG_CHECK="~USB_NET_CDC_NCM ~USB_USBNET ~IPV6"
ERROR_USB_NET_CDC_NCM="CONFIG_USB_NET_CDC_NCM is required to communicate with Apple T2 USB Ethernet (05ac:8233)."
ERROR_USB_USBNET="CONFIG_USB_USBNET is required for USB networking drivers."
ERROR_IPV6="CONFIG_IPV6 is required to communicate with the Secure Enclave over link-local IPv6."

pkg_pretend() {
	linux-info_pkg_setup

	if has_version sys-auth/libfprint; then
		local libdir=$(get_libdir)
		local so_files=( "${EROOT}"/usr/${libdir}/libfprint-2.so* )
		if [[ -f "${so_files[0]}" ]]; then
			if ! grep -q -a "FP_VIRTUAL_DEVICE_STORAGE" "${so_files[@]}" 2>/dev/null; then
				ewarn "=========================================================================="
				ewarn " WARNING: Installed sys-auth/libfprint lacks virtual driver support!"
				ewarn " Touch ID requires libfprint built with '-Ddrivers=all'."
				ewarn " Rebuild sys-auth/libfprint from the overlay with USE=\"virtual-drivers\""
				ewarn " or add myemesonargs=(\"-Ddrivers=all\") to package.env."
				ewarn "=========================================================================="
			fi
		fi
	fi
}

pkg_setup() {
	linux-info_pkg_setup
}

src_compile() {
	cargo_src_compile
}

src_test() {
	cargo_src_test
}

src_install() {
	# Install compiled binary
	cargo_src_install

	# Configuration file
	insinto /etc/kait2en
	newins config/t2-touchid.conf t2-touchid.conf

	# D-Bus system policy (broadcasts prompt state for Touch Bar animation)
	insinto /usr/share/dbus-1/system.d
	doins integration/dbus/org.kait2en.TouchId.conf

	# Systemd service and fprintd drop-in
	if use systemd; then
		sed "s|@BINDIR@|${EPREFIX}/usr/bin|g" \
			integration/systemd/kait2en-t2-touchid.service > "${T}/kait2en-t2-touchid.service" || die
		systemd_dounit "${T}/kait2en-t2-touchid.service"

		# fprintd configuration drop-in pointing FP_VIRTUAL_DEVICE_STORAGE to the bridge socket
		insinto "$(systemd_get_systemunitdir)/fprintd.service.d"
		doins integration/fprintd/fprintd-kait2en-t2-touchid.conf
	fi

	# OpenRC init and conf files
	newinitd "${FILESDIR}/t2-touchid.initd" t2-touchid
	newconfd "${FILESDIR}/t2-touchid.confd" t2-touchid

	# Network profiles for the internal Apple T2 CDC-NCM link (MAC ac:de:48:00:11:22)
	local shared_dir="${S}/../shared"
	if use networkmanager; then
		insinto /etc/NetworkManager/conf.d
		doins "${shared_dir}/integration/NetworkManager/10-t2-services.conf"
		insinto /etc/NetworkManager/system-connections
		doins "${shared_dir}/integration/NetworkManager/t2-ncm.nmconnection"
		fperms 0600 /etc/NetworkManager/system-connections/t2-ncm.nmconnection
	elif use systemd; then
		insinto /usr/lib/systemd/network
		doins "${FILESDIR}/10-t2-ncm.network"
	fi

	# PAM configuration helper tool
	dosbin "${FILESDIR}/t2-touchid-pam"

	dodoc README.md
}

pkg_postinst() {
	elog "=========================================================================="
	elog " Apple T2 Touch ID Bridge (t2-touchid) - Setup Instructions"
	elog "=========================================================================="
	elog "1. IMPORTANT: sys-auth/libfprint MUST be built with '-Ddrivers=all'!"
	elog "   Gentoo's default libfprint excludes virtual storage device drivers."
	elog "   To recompile libfprint with virtual drivers, add to /etc/portage/env/libfprint:"
	elog "     myemesonargs=(\"-Ddrivers=all\")"
	elog "   and map it in /etc/portage/package.env:"
	elog "     sys-auth/libfprint libfprint"
	elog "   then run: emerge --ask sys-auth/libfprint"
	elog ""
	elog "2. Kernel configuration:"
	elog "   Ensure CONFIG_USB_NET_CDC_NCM=y (or m) and CONFIG_IPV6=y are enabled."
	elog "   The internal Apple T2 USB Ethernet device (05ac:8233) must be UP"
	elog "   and configured with an IPv6 link-local address."
	elog ""
	elog "3. Touch ID Enrollment in macOS:"
	elog "   Enrol your fingerprints under macOS first! Linux cannot enrol new"
	elog "   prints directly into the Secure Enclave Processor (SEP)."
	elog "   Also ensure you have logged in with your password in macOS at least once"
	elog "   since the last cold boot to unlock the SEP biometric keybag."
	elog ""
	elog "4. Service Activation:"
	if use systemd; then
		elog "   Systemd:"
		elog "     # systemctl daemon-reload"
		elog "     # systemctl enable --now kait2en-t2-touchid.service"
		elog "     # systemctl try-restart fprintd.service"
	else
		elog "   OpenRC:"
		elog "     # rc-update add t2-touchid default"
		elog "     # rc-service t2-touchid start"
	fi
	elog ""
	elog "5. Binding to your Linux account:"
	elog "   Edit /etc/kait2en/t2-touchid.conf to set T2_TOUCHID_BIND_USER=\"<username>\""
	elog "   to bind enrolled fingers automatically, or run:"
	elog "     $ fprintd-enroll"
	elog ""
	elog "6. Complementary PAM Authentication (Touch ID + Password):"
	elog "   Enable Touch ID with password fallback for sudo using the included helper:"
	elog "     # t2-touchid-pam --enable sudo"
	elog "   Check status anytime with:"
	elog "     # t2-touchid-pam --status sudo"
	elog "=========================================================================="
}
