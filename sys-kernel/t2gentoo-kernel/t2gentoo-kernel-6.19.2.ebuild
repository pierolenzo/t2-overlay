# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KERNEL_IUSE_MODULES_SIGN=1
KERNEL_IUSE_GENERIC_UKI=1
inherit kernel-build toolchain-funcs verify-sig

BASE_P=linux-${PV%.*}
PATCH_PV=${PV%_p*}
PATCHSET=linux-gentoo-patches-6.18.4
# https://koji.fedoraproject.org/koji/packageinfo?packageID=8
# forked to https://github.com/projg2/fedora-kernel-config-for-gentoo
CONFIG_VER=6.19.2-gentoo
GENTOO_CONFIG_VER=g18
LINUX_T2_PATCHES_VER="4fcd61758fe6ef80dc9a268554a92ff231fa80cf"
SHA256SUM_DATE=20260217

DESCRIPTION="Linux kernel built with Gentoo patches and t2linux patches"
HOMEPAGE="
	https://wiki.gentoo.org/wiki/Project:Distribution_Kernel
	https://www.kernel.org/
	https://t2linux.org/
"
SRC_URI+="
	https://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/${BASE_P}.tar.xz
	https://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/patch-${PATCH_PV}.xz
	https://dev.gentoo.org/~mgorny/dist/linux/${PATCHSET}.tar.xz
	https://github.com/projg2/gentoo-kernel-config/archive/${GENTOO_CONFIG_VER}.tar.gz
			-> gentoo-kernel-config-${GENTOO_CONFIG_VER}.tar.gz
	https://github.com/t2linux/linux-t2-patches/archive/${LINUX_T2_PATCHES_VER}.tar.gz
			-> linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz
	verify-sig? (
			https://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/sha256sums.asc
					-> linux-$(ver_cut 1).x-sha256sums-${SHA256SUM_DATE}.asc
	)
	amd64? (
			https://raw.githubusercontent.com/projg2/fedora-kernel-config-for-gentoo/${CONFIG_VER}/kernel-x86_64-fedora.config
					-> kernel-x86_64-fedora.config.${CONFIG_VER}
	)
"
S=${WORKDIR}/${BASE_P}

LICENSE="GPL-2"
KEYWORDS="~amd64"
IUSE="debug hardened"

RDEPEND="
	!sys-kernel/gentoo-kernel-bin:${SLOT}
"
BDEPEND="
	debug? ( dev-util/pahole )
	verify-sig? ( >=sec-keys/openpgp-keys-kernel-20250702 )
"
PDEPEND="
	>=virtual/dist-kernel-${PV}
"

QA_FLAGS_IGNORED="
	usr/src/linux-.*/scripts/gcc-plugins/.*.so
	usr/src/linux-.*/vmlinux
"

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/kernel.org.asc

src_unpack() {
	if use verify-sig; then
		cd "${DISTDIR}" || die
		verify-sig_verify_signed_checksums \
			"linux-$(ver_cut 1).x-sha256sums-${SHA256SUM_DATE}.asc" \
			sha256 "${BASE_P}.tar.xz patch-${PATCH_PV}.xz"
		cd "${WORKDIR}" || die
	fi

	default
}

src_prepare() {

	local patch
	eapply "${WORKDIR}/patch-${PATCH_PV}"
	eapply "${WORKDIR}/${PATCHSET}"
	eapply "${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}"

	default

	# add Gentoo patchset version
	local extraversion=${PV#${PATCH_PV}}
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${extraversion/_/-}:" Makefile || die


	# prepare the default config
	case ${ARCH} in
		amd64)
			cp "${DISTDIR}/kernel-x86_64-fedora.config.${CONFIG_VER}" .config || die
			;;
		*)
			die "Unsupported arch ${ARCH}"
			;;
	esac

	local myversion="-t2gentoo-dist"
	use hardened && myversion+="-hardened"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${T}"/version.config || die
	local dist_conf_path="${WORKDIR}/gentoo-kernel-config-${GENTOO_CONFIG_VER}"

	local merge_configs=(
		"${T}"/version.config
		"${dist_conf_path}"/base.config
		"${dist_conf_path}"/6.12+.config
		"${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}/extra_config"
	)

	use debug || merge_configs+=(
		"${dist_conf_path}"/no-debug.config
	)

	if use hardened; then
		merge_configs+=( "${dist_conf_path}"/hardened-base.config )

		tc-is-gcc && merge_configs+=( "${dist_conf_path}"/hardened-gcc-plugins.config )

		if [[ -f "${dist_conf_path}/hardened-${ARCH}.config" ]]; then
			merge_configs+=( "${dist_conf_path}/hardened-${ARCH}.config" )
		fi
	fi

	use secureboot && merge_configs+=(
		"${dist_conf_path}/secureboot.config"
		"${dist_conf_path}/zboot.config"
	)

	kernel-build_merge_configs "${merge_configs[@]}"
}
