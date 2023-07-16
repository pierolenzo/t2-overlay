# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit python-single-r1 s6 systemd

DESCRIPTION="Daemon for controlling Touch Bar on your Mac with T2 security chip"
HOMEPAGE="https://github.com/NoaHimesaka1873/touchbard"
SRC_URI="https://github.com/NoaHimesaka1873/touchbard/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}"

src_install() {
	python_doscript "${S}/touchbard"
	python_doscript "${S}/touchbarctl"

	insinto /etc
	newins "${S}/touchbard.example.conf" "touchbard.conf"

	use systemd && systemd_dounit "${S}/touchbard.service"
	doinitd "${FILESDIR}/touchbard"
	s6_install_service "${FILESDIR}/touchbard.s6"
}

pkg_postinst() {
	elog "To enable touchbard:"
	elog "[openrc] rc-update add touchbard default && rc-service touchbard start"
	elog "[systemd] systemctl enable --now touchbard"
	elog "To change the touchbar mode, edit /etc/touchbard.conf and change the fnmode"
	elog "option according to the comments."
}
