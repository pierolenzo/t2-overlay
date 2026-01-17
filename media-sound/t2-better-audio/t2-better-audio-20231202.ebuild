# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit optfeature udev

DESCRIPTION="Audio configuration files for T2 Macbooks."
HOMEPAGE="https://wiki.t2linux.org/guides/audio-config/"
T2_BETTER_AUDIO_COMMIT="e46839a28963e2f7d364020518b9dac98236bcae"
SRC_URI="https://github.com/kekrby/t2-better-audio/archive/${T2_BETTER_AUDIO_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${T2_BETTER_AUDIO_COMMIT}"
IUSE="pulseaudio"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

src_install() {
	dirs=( "/usr/share/alsa-card-profile/mixer" )
	use pulseaudio && dirs+=( "/usr/share/pulseaudio/alsa-mixer" )
	for dir in "${dirs[@]}"; do
		insinto "${dir}"
		doins -r "${S}"/files/paths
		doins -r "${S}"/files/profile-sets
	done

	udev_dorules "${S}"/files/91-audio-custom.rules
}

pkg_postinst() {
	if use pulseaudio; then
		ewarn "It seems you have the pulseaudio USE flag enabled. If you are using pipewire,"
		ewarn "this USE flag is not needed. If you are using pulseaudio, it is recommended"
		ewarn "to switch to media-sound/pipewire for a superior audio experience."
	fi
	optfeature "superior audio" media-sound/pipewire
	optfeature "realtime audio scheduling with Pipewire (smoother audio)" app-auth/rtkit
}
