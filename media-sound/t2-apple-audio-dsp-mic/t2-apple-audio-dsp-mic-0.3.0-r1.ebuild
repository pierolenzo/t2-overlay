# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Apple T2 mic DSP configs"
HOMEPAGE="https://t2linux.org/"
SRC_URI="https://github.com/lemmyg/t2-apple-audio-dsp/archive/refs/tags/mic-v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${PN}-v${PV}"

RDEPEND="
	media-plugins/swh-plugins
	media-video/pipewire[sound-server]
	media-video/wireplumber
"

src_install() {
	insinto /etc/pipewire/pipewire.conf.d
	doins "${S}/config/10-t2_mic.conf"
	doins "${S}/config/10-t2_headset_mic.conf"
}

pkg_postinst() {
	einfo "Please restart pipewire and wireplumber for this package to take effect."
}
