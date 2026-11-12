# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo desktop git-r3 xdg-utils

DESCRIPTION="GTK4/libadwaita device topology and runtime power state explorer for Apple T2 MacBooks (Live git master)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/apps/t2-power-explorer"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""

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

src_unpack() {
	git-r3_src_unpack
	pushd "${S}" >/dev/null || die
	cargo_live_src_unpack
	popd >/dev/null || die
}

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
	elif [[ -f "${WORKDIR}/${P}/website/docs/post-install/applications/t2-power-explorer.md" ]]; then
		newdoc "${WORKDIR}/${P}/website/docs/post-install/applications/t2-power-explorer.md" README.md
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
