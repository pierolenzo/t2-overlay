# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit python-single-r1 systemd

DESCRIPTION="A simple daemon to control fan speed on Macs with T2 chip"
HOMEPAGE="https://github.com/NoaHimesaka1873/t2fand"
SRC_URI="https://github.com/NoaHimesaka1873/t2fand/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}"

src_install() {
	python_doscript "${S}/t2fand"

	use systemd && systemd_dounit "${S}/t2fand.service"
	doinitd "${FILESDIR}/t2fand"
}

pkg_postinst() {
	elog "To enable t2fand:"
	elog "[openrc] rc-update add t2fand default && rc-service t2fand start"
	elog "[systemd] systemctl enable --now t2fand"
}
