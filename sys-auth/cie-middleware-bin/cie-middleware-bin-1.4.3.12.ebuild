# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop multilib

DESCRIPTION="Middleware for the Italian Electronic Identity Card (CIE)"
HOMEPAGE="https://github.com/italia/cie-middleware-linux"
SRC_URI="https://github.com/italia/cie-middleware-linux/releases/download/${PV}/CIE-Middleware-$(ver_rs 3 -).x86-64.tar.gz"

LICENSE="BSD-3-Clause"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip mirror"

RDEPEND="
	virtual/jre
	sys-libs/glibc
	dev-libs/openssl
	sys-apps/pcsc-lite
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

QA_PREBUILT="*"

src_prepare() {
	default
	# Correct the Exec and Icon paths in the desktop file
	sed -i 's|Exec=.*|Exec=/usr/bin/cieid|' usr/share/applications/cieid.desktop || die
	sed -i 's|Icon=.*|Icon=/usr/share/pixmaps/cieid.png|' usr/share/applications/cieid.desktop || die
}

src_install() {
	# Install the main application to /opt/cieid
	insinto /opt/cieid
	doins usr/share/CIEID/cieid.jar

	# Install the PKCS#11 library to /usr/lib64
	dolib.so usr/local/lib/libcie-pkcs11.so

	# Create a wrapper script in /usr/bin
	newbin - cieid <<-_EOF_
		#!/bin/sh
		exec java -Xms1G -Xmx1G -Djna.library.path="${EPREFIX}/usr/$(get_libdir)" -classpath "${EPREFIX}/opt/cieid/cieid.jar" it.ipzs.cieid.MainApplication "\$@"
	_EOF_

	# Install the icon and desktop entry
	newicon usr/share/CIEID/logo_circle.png cieid.png
	domenu usr/share/applications/cieid.desktop
}
