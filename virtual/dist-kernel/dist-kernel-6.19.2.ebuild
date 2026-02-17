# Copyright 2021-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Virtual to depend on any Distribution Kernel"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0/${PV}"
KEYWORDS="~amd64"

RDEPEND="
	|| (
		~sys-kernel/t2gentoo-kernel-${PV}
		~sys-kernel/gentoo-kernel-${PV}
		~sys-kernel/gentoo-kernel-bin-${PV}
		~sys-kernel/vanilla-kernel-${PV}
	)"
