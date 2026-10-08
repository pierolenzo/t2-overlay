# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo git-r3 linux-info systemd udev

DESCRIPTION="Dark-first Touch Bar daemon for Apple T2 MacBooks (live git)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/apps/t2-touchbar"

LICENSE="GPL-3+ MIT Apache-2.0 BSD Unicode-3.0"
SLOT="0"
KEYWORDS=""
IUSE="elogind systemd"
REQUIRED_USE="?? ( elogind systemd )"

RDEPEND="
	dev-libs/libinput:=
	virtual/udev
	|| (
		media-fonts/adwaita-fonts
		media-fonts/inter
		media-fonts/cantarell
	)
	elogind? ( sys-auth/elogind )
	systemd? ( sys-apps/systemd )
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
"

QA_FLAGS_IGNORED="usr/bin/kait2en-touchbar"

# Kernel configuration requirements for Apple T2 Touch Bar
CONFIG_CHECK="~DRM_APPLETBDRM ~HID_APPLETB_BL ~HID_APPLETB_KBD ~INPUT_UINPUT ~BACKLIGHT_CLASS_DEVICE"
ERROR_DRM_APPLETBDRM="CONFIG_DRM_APPLETBDRM is required for Touch Bar DRM display."
ERROR_HID_APPLETB_BL="CONFIG_HID_APPLETB_BL is required for Touch Bar backlight control."
ERROR_HID_APPLETB_KBD="CONFIG_HID_APPLETB_KBD is required for Touch Bar keyboard input."
ERROR_INPUT_UINPUT="CONFIG_INPUT_UINPUT is required for virtual key event injection."
ERROR_BACKLIGHT_CLASS_DEVICE="CONFIG_BACKLIGHT_CLASS_DEVICE is required for backlight control."

pkg_pretend() {
	linux-info_pkg_setup
}

pkg_setup() {
	rust_pkg_setup
	linux-info_pkg_setup
}

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

PATCHES=(
	"${FILESDIR}/0001-wait-for-drm-device-readiness.patch"
)

src_prepare() {
	default

	# Add Gentoo font paths to FONT_PATHS in renderer.rs
	sed -i 's|"/usr/share/fonts/adwaita-sans-fonts/AdwaitaSans-Regular.ttf",|"/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf",\n    "/usr/share/fonts/inter/InterVariable.ttf",\n    "/usr/share/fonts/cantarell/Cantarell-VF.otf",\n    "/usr/share/fonts/adwaita-sans-fonts/AdwaitaSans-Regular.ttf",|' src/renderer.rs || die
	sed -i 's|const FONT_PATHS: \[&str; 3\] = \[|const FONT_PATHS: [\&str; 6] = [|' src/renderer.rs || die

	# Adjust systemd service paths from /usr/local/bin to /usr/bin
	sed -i 's|/usr/local/bin|/usr/bin|g' \
		integration/systemd/user/kait2en-touchbar.service \
		integration/systemd/system/kait2en-touchbar-attach.service || die
}

src_compile() {
	cargo_src_compile
}

src_test() {
	cargo_src_test
}

src_install() {
	cargo_src_install --path ./

	# Configuration file
	insinto /etc/kait2en
	doins config/touchbar.toml

	# udev rule with standard Gentoo video and input groups
	udev_dorules "${FILESDIR}/99-t2-touchbar.rules"

	# systemd user session daemon (autonomously manages display attach/detach)
	if use systemd; then
		systemd_douserunit "${FILESDIR}/kait2en-touchbar.service"
	fi

	# OpenRC attach service
	newinitd "${FILESDIR}/kait2en-touchbar-attach.initd" kait2en-touchbar-attach
	newconfd "${FILESDIR}/kait2en-touchbar-attach.confd" kait2en-touchbar-attach

	# XDG desktop autostart entry for graphical desktop sessions
	insinto /etc/xdg/autostart
	doins "${FILESDIR}/kait2en-touchbar.desktop"

	dodoc README.md THIRD-PARTY-NOTICES.md
}

pkg_postinst() {
	udev_reload

	elog "=========================================================================="
	elog " Apple T2 Touch Bar (kait2en-touchbar) installed successfully!"
	elog ""
	elog " [Permissions & System Groups]"
	elog " Device nodes are governed by standard Gentoo system groups:"
	elog "   - 'video': grants access to Touch Bar DRM display, backlight and USB attach"
	elog "   - 'input': grants access to touch digitizer, Fn key and /dev/uinput"
	elog ""
	elog " Ensure your desktop user is a member of the 'video' and 'input' groups:"
	elog "   # usermod -aG video,input <username>"
	elog ""
	elog " [User Session Daemon & Autostart]"
	elog " Touch Bar initialization (attach) and panel control are now fully"
	elog " managed in user session. Start and enable the daemon with:"
	elog ""
	if use systemd; then
		elog "   $ systemctl --user enable --now kait2en-touchbar.service"
	else
		elog "   # rc-update add kait2en-touchbar-attach default"
		elog "   # rc-service kait2en-touchbar-attach start"
	fi
	elog "   The daemon is also configured to auto-start via XDG autostart"
	elog "   (/etc/xdg/autostart/kait2en-touchbar.desktop) upon graphical login."
	elog ""
	elog " [Firmware Fallback Mode]"
	elog " When the user daemon is stopped, the Touch Bar automatically remains in"
	elog " native firmware mode (ESC/F-keys/brightness/volume) on seat0."
	elog "=========================================================================="
}

pkg_postrm() {
	udev_reload
}
