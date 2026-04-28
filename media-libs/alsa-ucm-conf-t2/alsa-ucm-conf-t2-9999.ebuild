# Copyright 2023-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3

DESCRIPTION="ALSA UCM2 configuration files for T2 Macbooks"
HOMEPAGE="https://github.com/pierolenzo/alsa-ucm-conf-t2"
EGIT_REPO_URI="https://github.com/pierolenzo/alsa-ucm-conf-t2.git"

LICENSE="MIT"
SLOT="0"

RDEPEND="media-libs/alsa-ucm-conf"

src_install() {
	insinto /usr/share/alsa/ucm2
	doins -r ucm2/*
}

pkg_postinst() {
	elog "To apply the new audio routing, restart your audio server"
	elog "by running this command (WITHOUT sudo):"
	elog ""
	elog "    systemctl --user restart wireplumber pipewire"
	elog ""
	elog "If automatic headphone switching does not work initially,"
	elog "plug in your headphones and manually select them as the"
	elog "output device in your desktop audio settings or pwvucontrol."
}
