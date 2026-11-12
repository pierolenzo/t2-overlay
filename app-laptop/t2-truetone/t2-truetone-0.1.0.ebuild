# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	anyhow@1.0.104
	async-broadcast@0.7.2
	async-channel@2.5.0
	async-executor@1.14.1
	async-io@2.6.0
	async-lock@3.5.0
	async-process@2.5.0
	async-recursion@1.2.0
	async-signal@0.2.14
	async-task@4.7.1
	async-trait@0.1.92
	atomic-waker@1.1.2
	autocfg@1.5.1
	bitflags@2.13.2
	blocking@1.7.0
	bumpalo@3.20.3
	cairo-rs@0.20.12
	cairo-sys-rs@0.20.10
	cfg-expr@0.20.10
	cfg-if@1.0.5
	concurrent-queue@2.5.0
	crossbeam-utils@0.8.23
	endi@1.1.1
	enumflags2@0.7.12
	enumflags2_derive@0.7.12
	equivalent@1.0.3
	errno@0.3.14
	event-listener-strategy@0.5.4
	event-listener@5.4.2
	fastrand@2.5.0
	field-offset@0.3.6
	futures-channel@0.3.34
	futures-core@0.3.34
	futures-executor@0.3.34
	futures-io@0.3.34
	futures-lite@2.6.1
	futures-macro@0.3.34
	futures-task@0.3.34
	futures-util@0.3.34
	gdk-pixbuf-sys@0.20.10
	gdk-pixbuf@0.20.10
	gdk4-sys@0.9.6
	gdk4@0.9.6
	getrandom@0.4.3
	gio-sys@0.20.10
	gio@0.20.12
	glib-macros@0.20.12
	glib-sys@0.20.10
	glib@0.20.12
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
	hermit-abi@0.5.3
	hex@0.4.3
	indexmap@2.14.2
	itoa@1.0.19
	js-sys@0.3.107
	libadwaita-sys@0.7.2
	libadwaita@0.7.2
	libc@0.2.191
	linux-raw-sys@0.12.1
	memchr@2.8.3
	memoffset@0.9.1
	once_cell@1.21.4
	ordered-stream@0.2.0
	pango-sys@0.20.10
	pango@0.20.12
	parking@2.2.1
	pin-project-lite@0.2.17
	piper@0.2.5
	pkg-config@0.3.34
	polling@3.11.0
	proc-macro-crate@3.5.0
	proc-macro2@1.0.107
	quote@1.0.47
	r-efi@6.0.0
	rustc_version@0.4.1
	rustix@1.1.6
	rustversion@1.0.23
	semver@1.0.28
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.154
	serde_repr@0.1.21
	serde_spanned@0.6.9
	serde_spanned@1.1.3
	signal-hook-registry@1.4.8
	slab@0.4.12
	smallvec@1.16.5
	syn@2.0.119
	syn@3.0.10
	system-deps@7.0.8
	target-lexicon@0.13.5
	tempfile@3.27.0
	toml@0.8.23
	toml@1.2.1+spec-1.1.0
	toml_datetime@0.6.11
	toml_datetime@1.1.3+spec-1.1.0
	toml_edit@0.22.27
	toml_edit@0.25.19+spec-1.1.0
	toml_parser@1.1.5+spec-1.1.0
	toml_write@0.1.2
	toml_writer@1.2.0+spec-1.1.0
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing@0.1.44
	uds_windows@1.2.1
	unicode-ident@1.0.27
	uuid@1.29.2
	version-compare@0.2.1
	wasm-bindgen-macro-support@0.2.130
	wasm-bindgen-macro@0.2.130
	wasm-bindgen-shared@0.2.130
	wasm-bindgen@0.2.130
	windows-link@0.2.1
	windows-sys@0.59.0
	windows-sys@0.61.2
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.52.6
	winnow@0.7.15
	winnow@1.0.5
	zbus@5.19.0
	zbus_macros@5.19.0
	zbus_names@4.3.5
	zcheapstr@1.2.0
	zmij@1.0.23
	zvariant@5.15.1
	zvariant_derive@5.15.1
	zvariant_utils@4.2.0
"

inherit cargo desktop linux-info systemd udev xdg-utils

DESCRIPTION="Ambient white point adaptation, evening mode and automatic brightness for T2 MacBooks"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"

# Snapshot commit from kaiT2en-Fedora repository containing t2-truetone
COMMIT="6ddacd9f5994db284552957ae6550f08e03708d1"
SRC_URI="
	https://github.com/kaiT2en/KaiT2en-Fedora/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/KaiT2en-Fedora-${COMMIT}/apps/t2-truetone"

LICENSE="GPL-3+ Apache-2.0 BSD MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gnome-shell +gui systemd"

RDEPEND="
	dev-libs/wayland
	virtual/udev
	gui? (
		gui-libs/gtk:4
		gui-libs/libadwaita:1
		x11-libs/cairo
		x11-libs/pango
		x11-libs/gdk-pixbuf:2
	)
	gnome-shell? (
		gnome-base/gnome-shell
	)
	systemd? (
		sys-apps/systemd
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
"

QA_FLAGS_IGNORED="
	usr/bin/t2truetone
	usr/bin/t2-truetone
"

CONFIG_CHECK="~HIDRAW"
ERROR_HIDRAW="CONFIG_HIDRAW is required to access the T2 Ambient Light Sensor via /dev/hidraw."

pkg_pretend() {
	linux-info_pkg_setup
}

pkg_setup() {
	rust_pkg_setup
	linux-info_pkg_setup
}

PATCHES=(
	"${FILESDIR}/0001-support-wlroots-and-sysfs.patch"
)

src_prepare() {
	default

	# Fix hardcoded /usr/local/bin paths in desktop file and systemd service
	sed -i 's|/usr/local/bin|/usr/bin|g' \
		org.t2truetone.gtk.desktop \
		systemd/t2-truetone.service || die

	# Grant video group access to T2 ambient light sensor for Gentoo desktop sessions
	sed -i 's|TAG+="uaccess"|TAG+="uaccess", GROUP="video", MODE="0660"|g' \
		udev/70-t2-truetone.rules || die
}

src_compile() {
	cargo_src_compile $(usex gui "" "--no-default-features")
}

src_test() {
	cargo_src_test $(usex gui "" "--no-default-features")
}

src_install() {
	cargo_src_install --path ./ $(usex gui "" "--no-default-features")

	if use gui; then
		domenu org.t2truetone.gtk.desktop
		doicon -s scalable assets/icons/hicolor/scalable/apps/org.t2truetone.gtk.svg
	fi

	udev_dorules udev/70-t2-truetone.rules

	if use systemd; then
		systemd_douserunit systemd/t2-truetone.service
	fi

	insinto /etc/xdg/autostart
	doins "${FILESDIR}/t2-truetone-autostart.desktop"

	if use gnome-shell; then
		local ext_uuid="kait2en-autobrightness@kait2en"
		local ext_dir="/usr/share/gnome-shell/extensions/${ext_uuid}"
		insinto "${ext_dir}"
		doins integration/gnome-shell/${ext_uuid}/metadata.json
		doins integration/gnome-shell/${ext_uuid}/extension.js
	fi

	dodoc LICENSE
}

pkg_postinst() {
	udev_reload
	udevadm trigger --action=change --subsystem-match=hidraw 2>/dev/null || true
	if use gui; then
		xdg_icon_cache_reload
		xdg_desktop_database_update
	fi

	elog "=========================================================================="
	elog " T2 TrueTone (t2-truetone) installed successfully!"
	elog ""
	elog " [Ambient Light Sensor Access]"
	elog " The udev rule 70-t2-truetone.rules sets TAG+=\"uaccess\" on the T2 ALS"
	elog " (05ac:8262) to give active graphical user sessions access to /dev/hidraw*."
	elog ""
	elog " [Starting the Daemon]"
	if use systemd; then
		elog " With systemd user services, enable and start with:"
		elog "   $ systemctl --user enable --now t2-truetone.service"
	fi
	elog " An XDG autostart entry is installed at /etc/xdg/autostart for automatic"
	elog " launch in GNOME user sessions."
	elog ""
	if use gnome-shell; then
		elog " [GNOME Shell Extension]"
		elog " The extension 'kait2en-autobrightness@kait2en' was installed."
		elog " You can enable it with:"
		elog "   $ gnome-extensions enable kait2en-autobrightness@kait2en"
	fi
	elog "=========================================================================="
}

pkg_postrm() {
	udev_reload
	if use gui; then
		xdg_icon_cache_reload
		xdg_desktop_database_update
	fi
}
