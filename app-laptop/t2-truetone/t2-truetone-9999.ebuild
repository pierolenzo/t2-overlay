# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo desktop git-r3 linux-info systemd udev xdg-utils

DESCRIPTION="Ambient white point adaptation, evening mode and automatic brightness for T2 MacBooks (live git)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/apps/t2-truetone"

LICENSE="GPL-3+ Apache-2.0 BSD MIT Unicode-3.0"
SLOT="0"
KEYWORDS=""
IUSE="gnome-shell +gui systemd"

RDEPEND="
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
	elog " T2 TrueTone (t2-truetone) live version installed successfully!"
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
