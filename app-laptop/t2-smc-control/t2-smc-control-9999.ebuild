# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo desktop git-r3 linux-info systemd xdg-utils

DESCRIPTION="GTK4/libadwaita control app and gauging daemon for Apple T2 MacBooks (Live git master)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/apps/t2-smc-control"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="+systemd"

RDEPEND="
	dev-libs/glib:2
	gui-libs/gtk:4
	gui-libs/libadwaita:1
	x11-libs/cairo
	x11-libs/pango
	x11-libs/gdk-pixbuf:2
	sys-apps/util-linux
	sys-auth/polkit
	systemd? (
		sys-apps/systemd
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-libs/glib:2
	virtual/pkgconfig
"

QA_FLAGS_IGNORED="
	usr/bin/t2-smc-control
"

CONFIG_CHECK="~MFD_MACSMC_CORE ~SENSORS_MACSMC_HWMON ~MACSMC_POWER"
ERROR_MFD_MACSMC_CORE="CONFIG_MFD_MACSMC_CORE is required for Apple T2 SMC communication."
ERROR_SENSORS_MACSMC_HWMON="CONFIG_SENSORS_MACSMC_HWMON is required for fan speeds and temperatures."
ERROR_MACSMC_POWER="CONFIG_MACSMC_POWER is required for battery and power supply telemetry."

pkg_pretend() {
	linux-info_pkg_setup
}

pkg_setup() {
	rust_pkg_setup
	linux-info_pkg_setup
}

src_unpack() {
	git-r3_src_unpack
	pushd "${S}" >/dev/null || die
	cargo_live_src_unpack
	popd >/dev/null || die
}

src_prepare() {
	default

	# Fix hardcoded /usr/local/bin paths in desktop file and systemd service
	sed -i 's|/usr/local/bin|/usr/bin|g' \
		org.t2smccontrol.gtk.desktop \
		systemd/t2-smc-gaugingd.service || die
}

src_compile() {
	cargo_src_compile
}

src_install() {
	dobin "$(cargo_target_dir)/t2-smc-control"

	domenu org.t2smccontrol.gtk.desktop
	doicon -s scalable assets/icons/hicolor/scalable/apps/org.t2smccontrol.gtk.svg

	if use systemd; then
		systemd_dounit systemd/t2-smc-gaugingd.service
	fi

	keepdir /var/lib/t2-smc-control/gauging
	fperms 0755 /var/lib/t2-smc-control/gauging

	dodoc README.md
}

pkg_postinst() {
	xdg_icon_cache_reload
	xdg_desktop_database_update

	if use systemd; then
		elog "=========================================================================="
		elog " T2 SMC Control (t2-smc-control) installed successfully!"
		elog ""
		elog " [Battery Gauge Calibration Service]"
		elog " To enable the background calibration daemon (t2-smc-gaugingd):"
		elog "   # systemctl enable --now t2-smc-gaugingd.service"
		elog "=========================================================================="
	fi
}

pkg_postrm() {
	xdg_icon_cache_reload
	xdg_desktop_database_update
}
