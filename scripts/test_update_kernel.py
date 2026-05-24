#!/usr/bin/env python3
import os
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))
import update_kernel


VALID_SHA = "a" * 40
OLD_SHA = "b" * 40


UPSTREAM_EBUILD = """# Copyright 2020-2026 Gentoo Authors
EAPI=8

GENTOO_CONFIG_P=gentoo-kernel-config-g19
DESCRIPTION="Linux kernel built with Gentoo patches"
HOMEPAGE="
\thttps://wiki.gentoo.org/wiki/Project:Distribution_Kernel
\thttps://www.kernel.org/
"
SRC_URI+="
\thttps://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/${BASE_P}.tar.xz
\tverify-sig? (
\t\thttps://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/sha256sums.asc
\t)
"

KEYWORDS="~amd64 ~arm64"
REQUIRED_USE="arm64? ( foo )"

src_prepare() {
\teapply "${WORKDIR}/patch-${PATCH_PV}"
\teapply "${WORKDIR}/${PATCHSET}"

\tcase ${ARCH} in
\t\tamd64)
\t\t\tcp amd64.config .config || die
\t\t\t;;
\t\tarm64)
\t\t\tcp arm64.config .config || die
\t\t\t;;
\tesac

\tlocal myversion="-gentoo-dist"
\tlocal dist_conf_path="${WORKDIR}/${GENTOO_CONFIG_P}"
\tlocal merge_configs=(
\t\t"${T}"/version.config
\t\t"${dist_conf_path}"/base.config
\t\t"${dist_conf_path}"/6.12+.config
\t)
}
"""


UPSTREAM_VIRTUAL = """EAPI=8

DESCRIPTION="Virtual to depend on any Distribution Kernel"
SLOT="0/${PVR}"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
\t|| (
\t\t~sys-kernel/gentoo-kernel-${PV}
\t\t~sys-kernel/gentoo-kernel-bin-${PV}
\t)
"
"""


class VersionTests(unittest.TestCase):
    def test_parse_version_key_orders_patch_and_revision(self):
        self.assertGreater(
            update_kernel.parse_version_key("6.12.91-r1"),
            update_kernel.parse_version_key("6.12.91"),
        )
        self.assertGreater(
            update_kernel.parse_version_key("6.12.91_p1"),
            update_kernel.parse_version_key("6.12.91-r9"),
        )

    def test_highest_branch_ebuild_understands_revisions(self):
        files = [
            "gentoo-kernel-6.12.90.ebuild",
            "gentoo-kernel-6.12.91.ebuild",
            "gentoo-kernel-6.12.91-r1.ebuild",
            "gentoo-kernel-6.12.91_p1.ebuild",
            "gentoo-kernel-6.13.1.ebuild",
        ]
        self.assertEqual(
            update_kernel.get_highest_branch_ebuild(files, "gentoo-kernel", "6.12"),
            "gentoo-kernel-6.12.91_p1.ebuild",
        )

    def test_select_target_version_adopts_upstream_revision(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            existing = Path(tmpdir) / "t2gentoo-kernel-6.12.91.ebuild"
            existing.write_text(f'LINUX_T2_PATCHES_VER="{VALID_SHA}"\n', encoding="utf-8")

            target, needs_update, current_sha = update_kernel.select_target_version(
                tmpdir, "6.12.91-r1", VALID_SHA
            )

        self.assertEqual(target, "6.12.91-r1")
        self.assertTrue(needs_update)
        self.assertEqual(current_sha, VALID_SHA)

    def test_select_target_version_bumps_revision_for_new_sha(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            existing = Path(tmpdir) / "t2gentoo-kernel-6.12.91-r1.ebuild"
            existing.write_text(f'LINUX_T2_PATCHES_VER="{OLD_SHA}"\n', encoding="utf-8")

            target, needs_update, current_sha = update_kernel.select_target_version(
                tmpdir, "6.12.91-r1", VALID_SHA
            )

        self.assertEqual(target, "6.12.91-r2")
        self.assertTrue(needs_update)
        self.assertEqual(current_sha, OLD_SHA)


class TransformTests(unittest.TestCase):
    def test_transform_ebuild_adds_t2_bits_and_restricts_keywords(self):
        generated = update_kernel.transform_ebuild(UPSTREAM_EBUILD, VALID_SHA)

        self.assertIn(f'LINUX_T2_PATCHES_VER="{VALID_SHA}"', generated)
        self.assertIn('KEYWORDS="~amd64"', generated)
        self.assertIn("linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz", generated)
        self.assertIn(
            'eapply "${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}"',
            generated,
        )
        self.assertIn(
            '"${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}/extra_config"',
            generated,
        )
        self.assertIn('myversion="-t2gentoo-dist"', generated)
        self.assertNotIn("REQUIRED_USE=", generated)

    def test_transform_ebuild_fails_when_upstream_shape_changes(self):
        broken = UPSTREAM_EBUILD.replace('\teapply "${WORKDIR}/${PATCHSET}"\n', "")
        with self.assertRaises(update_kernel.UpdateError):
            update_kernel.transform_ebuild(broken, VALID_SHA)

    def test_transform_virtual_adds_t2_dependency(self):
        generated = update_kernel.transform_virtual(UPSTREAM_VIRTUAL)

        self.assertIn('KEYWORDS="~amd64"', generated)
        self.assertIn("~sys-kernel/t2gentoo-kernel-${PV}", generated)


class BranchConfigTests(unittest.TestCase):
    def test_blank_kernel_branches_uses_defaults(self):
        original = os.environ.get("KERNEL_BRANCHES")
        os.environ["KERNEL_BRANCHES"] = ""
        try:
            self.assertEqual(
                update_kernel.get_configured_branches(),
                list(update_kernel.DEFAULT_BRANCHES),
            )
        finally:
            if original is None:
                os.environ.pop("KERNEL_BRANCHES", None)
            else:
                os.environ["KERNEL_BRANCHES"] = original


if __name__ == "__main__":
    unittest.main()
