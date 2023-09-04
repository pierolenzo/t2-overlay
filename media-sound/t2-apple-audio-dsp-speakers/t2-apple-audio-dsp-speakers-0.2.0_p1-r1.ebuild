# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Apple T2 speakers DSP configs"
HOMEPAGE="https://t2linux.org/"
SRC_URI="https://github.com/lemmyg/t2-apple-audio-dsp/archive/refs/tags/speakers-v$(ver_cut 1-3)-$(ver_cut 5).tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${PN}-v$(ver_cut 1-3)-$(ver_cut 5)"

RDEPEND="
	media-libs/lsp-plugins[lv2]
	media-plugins/calf[lv2]
	media-plugins/swh-plugins
	media-video/pipewire[lv2,sound-server]
	media-video/wireplumber
"

src_install() {
	insinto /etc/pipewire/pipewire.conf.d
	doins "${S}/config/10-t2_161_speakers.conf"
	insinto /usr/share/pipewire/devices/apple
	doins "${S}/firs/"*.wav
}

pkg_postinst() {
	einfo "Please restart pipewire and wireplumber for this package to take effect."
}
