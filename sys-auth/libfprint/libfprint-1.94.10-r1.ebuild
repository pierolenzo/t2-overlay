# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic meson toolchain-funcs udev

MY_P="${PN}-v${PV}"

DESCRIPTION="Library to add support for consumer fingerprint readers"
HOMEPAGE="
	https://fprint.freedesktop.org/
	https://gitlab.freedesktop.org/libfprint/libfprint
"
SRC_URI="
	!tod? (
		https://gitlab.freedesktop.org/${PN}/${PN}/-/archive/v${PV}/${MY_P}.tar.bz2 -> ${P}.tar.bz2
	)
	tod? (
		https://gitlab.freedesktop.org/3v1n0/${PN}/-/archive/v${PV}+tod1/${MY_P}+tod1.tar.bz2 -> ${P}+tod1.tar.bz2
	)
"
S="${WORKDIR}/${MY_P}"

LICENSE="LGPL-2.1+"
SLOT="2"
KEYWORDS="~amd64"
IUSE="examples gtk-doc +introspection tod +virtual-drivers"

RDEPEND="
	dev-libs/glib:2
	dev-libs/libgudev
	>=dev-libs/openssl-3:=
	dev-python/pygobject
	dev-libs/libgusb
	x11-libs/pixman
	examples? (
		x11-libs/gdk-pixbuf:2
		x11-libs/gtk+:3
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-util/glib-utils
	sys-devel/gettext
	virtual/pkgconfig
	gtk-doc? ( dev-util/gtk-doc )
	introspection? (
		>=dev-libs/gobject-introspection-1.82.0-r2
		dev-libs/libgusb[introspection]
	)
"

src_configure() {
	local emesonargs=(
		$(meson_use examples)
		$(meson_use gtk-doc doc)
		$(meson_use introspection)
		$(usex virtual-drivers "-Ddrivers=all" "-Ddrivers=default")
		-Dudev_rules=enabled
		-Dudev_rules_dir="$(get_udevdir)/rules.d"
	)
	meson_src_configure
}
