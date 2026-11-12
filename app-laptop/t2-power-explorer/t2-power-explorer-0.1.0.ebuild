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

inherit cargo desktop xdg-utils

DESCRIPTION="GTK4/libadwaita device topology and runtime power state explorer for Apple T2 MacBooks"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
COMMIT="6ddacd9f5994db284552957ae6550f08e03708d1"
SRC_URI="
	https://github.com/kaiT2en/KaiT2en-Fedora/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/KaiT2en-Fedora-${COMMIT}/apps/t2-power-explorer"

LICENSE="GPL-3+"
# Dependent crate licenses
LICENSE+=" Apache-2.0 BSD CC0-1.0 ISC MIT MPL-2.0 Unicode-DFS-2016"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-libs/glib:2
	gui-libs/gtk:4
	gui-libs/libadwaita:1
	x11-libs/cairo
	x11-libs/pango
	x11-libs/gdk-pixbuf:2
	sys-apps/hwdata
	sys-auth/polkit
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-libs/glib:2
	virtual/pkgconfig
"

QA_FLAGS_IGNORED="
	usr/bin/t2-power-explorer
"

PATCHES=(
	"${FILESDIR}/0001-power-explorer-paths-and-branding.patch"
)

src_compile() {
	cargo_src_compile
}

src_install() {
	dobin "$(cargo_target_dir)/t2-power-explorer"

	exeinto /usr/libexec
	doexe t2-power-explorer-status

	insinto /usr/share/polkit-1/actions
	doins org.t2powerexplorer.policy

	domenu org.t2powerexplorer.gtk.desktop
	doicon -s scalable assets/icons/hicolor/scalable/apps/org.t2powerexplorer.gtk.svg

	if [[ -f README.md ]]; then
		dodoc README.md
	elif [[ -f "${WORKDIR}/KaiT2en-Fedora-${COMMIT}/website/docs/post-install/applications/t2-power-explorer.md" ]]; then
		newdoc "${WORKDIR}/KaiT2en-Fedora-${COMMIT}/website/docs/post-install/applications/t2-power-explorer.md" README.md
	fi
	dodoc LICENSE
}

pkg_postinst() {
	xdg_icon_cache_reload
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_reload
	xdg_desktop_database_update
}
