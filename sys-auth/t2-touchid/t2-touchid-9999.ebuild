# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo linux-info multilib git-r3 systemd udev

DESCRIPTION="Bridges Apple T2 Touch ID sensor to fprintd via libfprint virtual device (live version)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/t2-services/t2-touchid"

LICENSE="GPL-3+ Apache-2.0 BSD MIT Unicode-3.0"
SLOT="0"
KEYWORDS=""
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
	virtual/pkgconfig
"

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
		local so_files=("${EROOT}"/usr/${libdir}/libfprint-2.so*)
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
	# Install compiled binary
	cargo_src_install

	# Configuration file
	insinto /etc/kait2en
	newins config/t2-touchid.conf t2-touchid.conf

	# D-Bus system policy
	insinto /usr/share/dbus-1/system.d
	doins integration/dbus/org.kait2en.TouchId.conf

	# Systemd service and fprintd drop-in
	if use systemd; then
		sed "s|@BINDIR@|${EPREFIX}/usr/bin|g" \
			integration/systemd/kait2en-t2-touchid.service >"${T}/kait2en-t2-touchid.service" || die
		systemd_dounit "${T}/kait2en-t2-touchid.service"

		insinto "$(systemd_get_systemunitdir)/fprintd.service.d"
		doins integration/fprintd/fprintd-kait2en-t2-touchid.conf
	fi

	# OpenRC init and conf files
	newinitd "${FILESDIR}/t2-touchid.initd" t2-touchid
	newconfd "${FILESDIR}/t2-touchid.confd" t2-touchid

	# Network configuration for Apple T2 CDC-NCM link
	local shared_dir="${S}/../shared"

	# CDC-NCM link is brought up via udev rule with link-local IPv6
	sed -e "s|/usr/sbin/ip|${EPREFIX}/bin/ip|g" \
		"${shared_dir}/integration/udev/90-t2-services-ncm.rules" > "${T}/90-t2-services-ncm.rules" || die
	udev_dorules "${T}/90-t2-services-ncm.rules"

	# Keep NetworkManager from managing the CDC-NCM link so suspend hooks work
	if use networkmanager; then
		insinto /etc/NetworkManager/conf.d
		doins "${shared_dir}/integration/NetworkManager/10-t2-services.conf"
	elif use systemd; then
		insinto /usr/lib/systemd/network
		doins "${FILESDIR}/10-t2-ncm.network"
	fi

	# PAM configuration helper tool
	dosbin "${FILESDIR}/t2-touchid-pam"

	dodoc README.md
}

pkg_postinst() {
	udev_reload

	elog "=========================================================================="
	elog " Apple T2 Touch ID Bridge (t2-touchid) - Setup Instructions"
	elog "=========================================================================="
	elog "1. Kernel configuration:"
	elog "   Ensure CONFIG_USB_NET_CDC_NCM=y (or m) and CONFIG_IPV6=y are enabled."
	elog ""
	elog "2. Touch ID Enrollment in macOS:"
	elog "   Enrol your fingerprints under macOS first! Also log into macOS once"
	elog "   after cold boot to unlock the SEP biometric keybag."
	elog ""
	elog "3. Service Activation:"
	if use systemd; then
		elog "   Systemd: systemctl enable --now kait2en-t2-touchid.service"
	else
		elog "   OpenRC:  rc-update add t2-touchid default && rc-service t2-touchid start"
	fi
	elog ""
	elog "4. Binding to your Linux account:"
	elog "   Set T2_TOUCHID_BIND_USER=\"<username>\" in /etc/kait2en/t2-touchid.conf"
	elog "   or run 'fprintd-enroll'."
	elog ""
	elog "5. Complementary PAM Authentication (Touch ID + Password):"
	elog "   Enable Touch ID with password fallback for sudo using the included helper:"
	elog "     # t2-touchid-pam --enable sudo"
	elog "   Check status anytime with:"
	elog "     # t2-touchid-pam --status sudo"
	elog "=========================================================================="

	if use networkmanager; then
		if [[ -f "${EROOT}/etc/NetworkManager/system-connections/t2-ncm.nmconnection" ]]; then
			elog ""
			elog "NOTE: Legacy NetworkManager profile detected at:"
			elog "  /etc/NetworkManager/system-connections/t2-ncm.nmconnection"
			elog "Upstream now leaves the T2 CDC-NCM link unmanaged by NetworkManager"
			elog "and manages it via udev (/usr/lib/udev/rules.d/90-t2-services-ncm.rules)."
			elog "Please remove the obsolete profile to avoid conflicts:"
			elog "  # rm /etc/NetworkManager/system-connections/t2-ncm.nmconnection"
			elog "  # nmcli connection reload"
		fi
	fi
}

pkg_postrm() {
	udev_reload
}
