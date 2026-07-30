# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

DESCRIPTION="TradingView Desktop Application"
HOMEPAGE="https://www.tradingview.com/desktop/"
SRC_URI="https://tvd-packages.tradingview.com/ubuntu/stable/latest/jammy/tradingview_amd64.deb -> ${P}.deb"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RESTRICT="bindist mirror strip"

RDEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	virtual/udev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_prepare() {
	default
	# Remove Debian-specific apt files if present
	rm -rf "${S}/etc" || die
}

src_install() {
	# Install application files into /opt/TradingView
	insinto /opt
	doins -r opt/TradingView

	# Ensure binaries are executable
	fperms 0755 /opt/TradingView/tradingview
	fperms 0755 /opt/TradingView/chrome_crashpad_handler

	# Create executable symlink in /usr/bin
	dosym -r /opt/TradingView/tradingview /usr/bin/tradingview

	# Install desktop entry and icon
	domenu usr/share/applications/tradingview.desktop
	doicon -s 512 usr/share/icons/hicolor/512x512/apps/tradingview.png
}
