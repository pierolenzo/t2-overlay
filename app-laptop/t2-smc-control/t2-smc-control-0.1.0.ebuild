# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	autocfg@1.5.1
	bitflags@2.13.2
	cairo-rs@0.20.12
	cairo-sys-rs@0.20.10
	cfg-expr@0.20.10
	equivalent@1.0.3
	field-offset@0.3.6
	futures-channel@0.3.34
	futures-core@0.3.34
	futures-executor@0.3.34
	futures-io@0.3.34
	futures-macro@0.3.34
	futures-task@0.3.34
	futures-util@0.3.34
	gdk-pixbuf-sys@0.20.10
	gdk-pixbuf@0.20.10
	gdk4-sys@0.9.6
	gdk4@0.9.6
	gio-sys@0.20.10
	gio@0.20.12
	glib-macros@0.20.12
	glib-sys@0.20.10
	glib@0.20.12
	glob@0.3.4
	gobject-sys@0.20.10
	graphene-rs@0.20.10
	graphene-sys@0.20.10
	gsk4-sys@0.9.6
	gsk4@0.9.6
	gtk4-macros@0.9.5
	gtk4-sys@0.9.6
	gtk4@0.9.7
	hashbrown@0.17.1
	heck@0.5.0
	indexmap@2.14.2
	libadwaita-sys@0.7.2
	libadwaita@0.7.2
	libc@0.2.191
	memchr@2.8.3
	memoffset@0.9.1
	pango-sys@0.20.10
	pango@0.20.12
	pin-project-lite@0.2.17
	pkg-config@0.3.34
	proc-macro-crate@3.5.0
	proc-macro2@1.0.107
	quote@1.0.47
	rustc_version@0.4.1
	semver@1.0.28
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_spanned@1.1.3
	slab@0.4.12
	smallvec@1.16.5
	syn@2.0.119
	syn@3.0.10
	system-deps@7.0.8
	target-lexicon@0.13.5
	toml@1.2.1+spec-1.1.0
	toml_datetime@1.1.3+spec-1.1.0
	toml_edit@0.25.19+spec-1.1.0
	toml_parser@1.1.5+spec-1.1.0
	toml_writer@1.2.0+spec-1.1.0
	unicode-ident@1.0.27
	version-compare@0.2.1
	windows-sys@0.59.0
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.52.6
	winnow@1.0.5
"

inherit cargo desktop linux-info systemd xdg-utils

DESCRIPTION="GTK4/libadwaita control app and gauging daemon for Apple T2 MacBooks"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"

COMMIT="6ddacd9f5994db284552957ae6550f08e03708d1"
SRC_URI="
	https://github.com/kaiT2en/KaiT2en-Fedora/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/KaiT2en-Fedora-${COMMIT}/apps/t2-smc-control"

LICENSE="GPL-3+ Apache-2.0 BSD MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"
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

PATCHES=(
	"${FILESDIR}/0001-support-macsmc-and-fix-branding.patch"
)

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

	insinto /usr/share/kait2en
	newins "${WORKDIR}/KaiT2en-Fedora-${COMMIT}/assets/kait2en-app-logo.png" kait2en-wordmark.png
	newins "${WORKDIR}/KaiT2en-Fedora-${COMMIT}/assets/kait2en-app-logo-light.png" kait2en-wordmark-light.png

	if use systemd; then
		systemd_dounit systemd/t2-smc-gaugingd.service
	fi

	keepdir /var/lib/t2-smc-control
	fperms 0755 /var/lib/t2-smc-control

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
