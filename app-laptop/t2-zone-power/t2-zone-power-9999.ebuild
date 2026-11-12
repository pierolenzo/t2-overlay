# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo desktop git-r3 linux-info systemd xdg-utils

DESCRIPTION="GTK4/libadwaita SMC power zones monitor and daemon for Apple T2 MacBooks (Live git master)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/apps/t2-zone-power"

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
	usr/bin/t2-zonepower-gtk
"

CONFIG_CHECK="~MFD_MACSMC_CORE ~SENSORS_MACSMC_HWMON ~MACSMC_POWER"
ERROR_MFD_MACSMC_CORE="CONFIG_MFD_MACSMC_CORE is required for Apple T2 SMC communication."
ERROR_SENSORS_MACSMC_HWMON="CONFIG_SENSORS_MACSMC_HWMON is required for power zones and temperatures."
ERROR_MACSMC_POWER="CONFIG_MACSMC_POWER is required for power telemetry."

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

PATCHES=(
	"${FILESDIR}/0001-zone-power-compat-and-paths.patch"
)

src_compile() {
	cargo_src_compile
}

src_install() {
	dobin "$(cargo_target_dir)/t2-zonepower-gtk"

	domenu org.t2zonepower.gtk.desktop
	doicon -s scalable assets/icons/hicolor/scalable/apps/org.t2zonepower.gtk.svg

	insinto /usr/share/kait2en
	newins "${WORKDIR}/${P}/assets/kait2en-app-logo.png" kait2en-wordmark.png
	newins "${WORKDIR}/${P}/assets/kait2en-app-logo-light.png" kait2en-wordmark-light.png

	if use systemd; then
		systemd_dounit systemd/t2-zonepowerd.service
	fi

	dodoc README.md
}

pkg_postinst() {
	xdg_icon_cache_reload
	xdg_desktop_database_update

	if use systemd; then
		elog "=========================================================================="
		elog " T2 Zone Power (t2-zone-power) installed successfully!"
		elog ""
		elog " [Power Zone Limiting Daemon]"
		elog " To enable the background power limiting daemon (t2-zonepowerd):"
		elog "   # systemctl enable --now t2-zonepowerd.service"
		elog "=========================================================================="
	fi
}

pkg_postrm() {
	xdg_icon_cache_reload
	xdg_desktop_database_update
}
