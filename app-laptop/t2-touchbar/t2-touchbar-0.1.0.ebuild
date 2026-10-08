# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	ab_glyph@0.2.32
	ab_glyph_rasterizer@0.1.10
	anyhow@1.0.104
	arrayref@0.3.9
	arrayvec@0.7.8
	async-broadcast@0.7.2
	async-channel@2.5.0
	async-executor@1.14.0
	async-io@2.6.0
	async-lock@3.4.2
	async-process@2.5.0
	async-recursion@1.1.1
	async-signal@0.2.14
	async-task@4.7.1
	async-trait@0.1.92
	atomic-waker@1.1.2
	autocfg@1.5.1
	bitflags@2.13.2
	blocking@1.7.0
	bumpalo@3.20.3
	bytemuck@1.25.2
	bytemuck_derive@1.12.1
	cfg-if@1.0.5
	cfg_aliases@0.2.2
	concurrent-queue@2.5.0
	crossbeam-utils@0.8.23
	drm-ffi@0.9.1
	drm-fourcc@2.2.0
	drm-sys@0.8.1
	drm@0.14.1
	endi@1.1.1
	enumflags2@0.7.12
	enumflags2_derive@0.7.12
	equivalent@1.0.2
	errno@0.3.14
	event-listener-strategy@0.5.4
	event-listener@5.4.2
	fastrand@2.5.0
	futures-core@0.3.34
	futures-io@0.3.34
	futures-lite@2.6.1
	futures-task@0.3.34
	futures-util@0.3.34
	getrandom@0.4.3
	hashbrown@0.17.1
	hermit-abi@0.3.9
	hermit-abi@0.5.3
	hex@0.4.3
	indexmap@2.14.2
	input-linux-sys@0.9.0
	input-linux@0.7.1
	input-sys@1.19.0
	input@0.9.1
	io-lifetimes@1.0.11
	js-sys@0.3.104
	libc@0.2.189
	libudev-sys@0.1.4
	linux-raw-sys@0.12.1
	linux-raw-sys@0.4.15
	linux-raw-sys@0.9.4
	log@0.4.34
	memchr@2.8.3
	memoffset@0.9.1
	nix@0.29.0
	once_cell@1.21.4
	ordered-stream@0.2.0
	owned_ttf_parser@0.25.1
	parking@2.2.1
	pin-project-lite@0.2.17
	piper@0.2.5
	pkg-config@0.3.34
	polling@3.11.0
	proc-macro-crate@3.5.0
	proc-macro2@1.0.107
	quote@1.0.47
	r-efi@6.0.0
	rustix@0.38.44
	rustix@1.1.5
	rustversion@1.0.23
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_repr@0.1.21
	serde_spanned@0.6.9
	signal-hook-registry@1.4.8
	slab@0.4.12
	strict-num@0.1.1
	syn@2.0.119
	syn@3.0.6
	tempfile@3.27.0
	tiny-skia-path@0.12.0
	tiny-skia@0.12.0
	toml@0.8.23
	toml_datetime@0.6.11
	toml_datetime@1.1.1+spec-1.1.0
	toml_edit@0.22.27
	toml_edit@0.25.15+spec-1.1.0
	toml_parser@1.1.3+spec-1.1.0
	toml_write@0.1.2
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing@0.1.44
	ttf-parser@0.25.1
	udev@0.9.3
	uds_windows@1.2.1
	unicode-ident@1.0.26
	uuid@1.26.1
	wasm-bindgen-macro-support@0.2.127
	wasm-bindgen-macro@0.2.127
	wasm-bindgen-shared@0.2.127
	wasm-bindgen@0.2.127
	windows-link@0.2.1
	windows-sys@0.48.0
	windows-sys@0.59.0
	windows-sys@0.61.2
	windows-targets@0.48.5
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.48.5
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.48.5
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.48.5
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.48.5
	windows_x86_64_msvc@0.52.6
	winnow@0.7.15
	winnow@1.0.4
	zbus@5.19.0
	zbus_macros@5.19.0
	zbus_names@4.3.4
	zcheapstr@1.1.0
	zvariant@5.15.0
	zvariant_derive@5.15.0
	zvariant_utils@4.2.0
"

inherit cargo linux-info systemd udev

DESCRIPTION="Dark-first Touch Bar daemon for Apple T2 MacBooks"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"

# Snapshot commit from kaiT2en-Fedora repository containing t2-touchbar
COMMIT="9b640bed73afd13b09a1552ea625920873ba2b80"
SRC_URI="
	https://github.com/kaiT2en/KaiT2en-Fedora/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/KaiT2en-Fedora-${COMMIT}/apps/t2-touchbar"

LICENSE="GPL-3+ MIT Apache-2.0 BSD Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"
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
