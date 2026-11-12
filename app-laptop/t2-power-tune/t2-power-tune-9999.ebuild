# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit desktop git-r3 python-single-r1 xdg-utils

DESCRIPTION="PCIe ASPM and power-saving tuning utility for Apple T2 MacBooks (Live git master)"
HOMEPAGE="https://github.com/kaiT2en/KaiT2en-Fedora"
EGIT_REPO_URI="https://github.com/kaiT2en/KaiT2en-Fedora.git"

S="${WORKDIR}/${P}/apps/t2-power-tune"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pygobject:3[${PYTHON_USEDEP}]
	')
	gui-libs/gtk:4
	gui-libs/libadwaita:1
	sys-apps/pciutils
	sys-auth/polkit
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}/0001-fix-paths-and-branding.patch"
)

src_install() {
	newbin t2-power-tune.py t2-power-tune
	exeinto /usr/libexec
	doexe t2-power-tune-helper
	doexe t2-power-tune-status

	python_fix_shebang "${ED}"/usr/bin "${ED}"/usr/libexec

	insinto /usr/share/polkit-1/actions
	doins org.t2powertune.policy

	domenu org.t2powertune.gtk.desktop
	doicon -s scalable org.t2powertune.gtk.svg

	insinto /usr/share/kait2en
	newins "${WORKDIR}/${P}/assets/kait2en-app-logo.png" kait2en-wordmark.png
	newins "${WORKDIR}/${P}/assets/kait2en-app-logo-light.png" kait2en-wordmark-light.png

	dodoc README.md
}

pkg_postinst() {
	xdg_icon_cache_reload
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_reload
	xdg_desktop_database_update
}
