#!/usr/bin/env python3
import glob
import json
import logging
import os
import re
import subprocess
import sys
import urllib.request


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

DEFAULT_BRANCHES = ("6.12", "6.18", "7.0", "7.1")
OVERLAY_DIR = os.environ.get("GITHUB_WORKSPACE") or os.getcwd()
REQUEST_TIMEOUT = int(os.environ.get("UPDATE_KERNEL_REQUEST_TIMEOUT", "60"))
GIT_TIMEOUT = int(os.environ.get("UPDATE_KERNEL_GIT_TIMEOUT", "60"))

_api_cache = {}
_VERSION_RE = re.compile(r"^(?P<base>\d+(?:\.\d+)*(?:_p\d+)?)(?:-r(?P<revision>\d+))?$")


class UpdateError(RuntimeError):
    pass


def get_configured_branches():
    branches = os.environ.get("KERNEL_BRANCHES", "").split()
    return branches or list(DEFAULT_BRANCHES)


def get_ebuild_version(filename, package):
    name = os.path.basename(filename)
    prefix = f"{package}-"
    suffix = ".ebuild"
    if not name.startswith(prefix) or not name.endswith(suffix):
        raise ValueError(f"{name} is not a {package} ebuild")
    return name[len(prefix):-len(suffix)]


def split_ebuild_revision(version):
    match = _VERSION_RE.fullmatch(version)
    if not match:
        raise ValueError(f"unsupported ebuild version: {version}")
    return match.group("base"), int(match.group("revision") or 0)


def format_ebuild_version(base, revision):
    if revision < 0:
        raise ValueError(f"invalid revision: {revision}")
    return f"{base}-r{revision}" if revision else base


def parse_version_key(version):
    base, revision = split_ebuild_revision(version)
    if "_p" in base:
        release, patch = base.split("_p", 1)
        patch = int(patch)
    else:
        release = base
        patch = 0
    release_parts = tuple(int(part) for part in release.split("."))
    return release_parts, patch, revision


def replace_once(content, pattern, replacement, description, flags=0):
    content, count = re.subn(pattern, replacement, content, flags=flags)
    if count != 1:
        raise UpdateError(
            f"Could not update {description}: expected one match, found {count}"
        )
    return content


def require_contains(content, needle, description):
    if needle not in content:
        raise UpdateError(f"Generated ebuild is missing {description}")


def get_codeberg_dir_files(path):
    if path in _api_cache:
        return _api_cache[path]
    url = f"https://codeberg.org/api/v1/repos/gentoo/gentoo/contents/{path}?ref=master"
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as response:
            data = json.loads(response.read().decode("utf-8"))
    except Exception as exc:
        raise UpdateError(f"Error fetching API {url}: {exc}") from exc

    if not isinstance(data, list):
        raise UpdateError(f"Unexpected API response for {url}")

    try:
        files = [entry["name"] for entry in data if entry["name"].endswith(".ebuild")]
    except (KeyError, TypeError) as exc:
        raise UpdateError(f"Unexpected API payload for {url}") from exc

    _api_cache[path] = files
    return files


def get_codeberg_raw_file(path, filename):
    url = f"https://codeberg.org/gentoo/gentoo/raw/branch/master/{path}/{filename}"
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as response:
            return response.read().decode("utf-8")
    except Exception as exc:
        raise UpdateError(f"Error downloading {url}: {exc}") from exc


def get_latest_t2_sha(branch):
    try:
        out = subprocess.check_output(
            [
                "git",
                "ls-remote",
                "https://github.com/t2linux/linux-t2-patches.git",
                f"refs/heads/{branch}",
            ],
            stderr=subprocess.STDOUT,
            text=True,
            timeout=GIT_TIMEOUT,
        )
    except subprocess.CalledProcessError as exc:
        raise UpdateError(
            f"git ls-remote failed for t2linux branch {branch}: {exc.output.strip()}"
        ) from exc
    except subprocess.TimeoutExpired as exc:
        raise UpdateError(f"git ls-remote timed out for t2linux branch {branch}") from exc

    if not out.strip():
        raise UpdateError(f"No t2linux branch found for {branch}")
    return out.split()[0]


def get_highest_branch_ebuild(files, package, branch):
    prefix = f"{package}-{branch}."
    branch_ebuilds = [filename for filename in files if filename.startswith(prefix)]
    if not branch_ebuilds:
        return None

    try:
        return max(
            branch_ebuilds,
            key=lambda filename: parse_version_key(get_ebuild_version(filename, package)),
        )
    except ValueError as exc:
        raise UpdateError(f"Could not parse upstream {package} ebuild version: {exc}") from exc


def get_highest_gentoo_version(branch):
    files = get_codeberg_dir_files("sys-kernel/gentoo-kernel")
    return get_highest_branch_ebuild(files, "gentoo-kernel", branch)


def transform_ebuild(content, sha):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise UpdateError(f"Invalid t2linux patch SHA: {sha}")

    content = replace_once(content, r'KEYWORDS=".*?"', 'KEYWORDS="~amd64"', "KEYWORDS")
    content = re.sub(r'REQUIRED_USE="[^"]*"\n?', "", content, count=1)
    content = replace_once(
        content,
        r"(GENTOO_CONFIG_P=.*?)\n",
        r'\1\nLINUX_T2_PATCHES_VER="' + sha + r'"\n',
        "t2linux patch version",
    )

    replacement = (
        "\n\t"
        "https://github.com/t2linux/linux-t2-patches/archive/${LINUX_T2_PATCHES_VER}.tar.gz"
        "\n\t\t\t-> linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz\\1"
    )
    content = replace_once(
        content,
        r"(\n[ \t]*verify-sig\? \(\n[ \t]*https://cdn\.kernel\.org/pub/linux/kernel/)",
        replacement,
        "t2linux patch SRC_URI",
    )

    content = replace_once(
        content,
        r"https://www\.kernel\.org/",
        "https://www.kernel.org/\n\thttps://t2linux.org/",
        "HOMEPAGE",
    )
    content = replace_once(
        content,
        r'DESCRIPTION="Linux kernel built with Gentoo patches"',
        'DESCRIPTION="Linux kernel built with Gentoo patches and t2linux patches"',
        "DESCRIPTION",
    )

    replacement_case = """case ${ARCH} in
\t\tamd64)
\t\t\tcp "${WORKDIR}/kernel-${CONFIG_VER}/kernel-x86_64-fedora.config" .config || die
\t\t\t;;
\t\t*)
\t\t\tdie "Unsupported arch ${ARCH}"
\t\t\t;;
\tesac"""
    content = replace_once(
        content,
        r"case \$\{ARCH\} in.*?esac",
        replacement_case,
        "ARCH config selection",
        flags=re.DOTALL,
    )

    content = replace_once(
        content,
        r'(eapply "\$\{WORKDIR\}/\$\{PATCHSET\}".*?\n)',
        r'\1\teapply "${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}"' + "\n",
        "t2linux eapply",
    )
    content = replace_once(
        content,
        r'myversion="-gentoo-dist"',
        'myversion="-t2gentoo-dist"',
        "local version",
    )
    content = replace_once(
        content,
        r'("\$\{dist_conf_path\}"/6\.12\+\.config)',
        r'\1' + "\n\t\t" + r'"${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}/extra_config"',
        "t2linux extra_config",
    )

    content = re.sub(r"\tlocal biendian=false\n", "", content, count=1)
    content = re.sub(
        r"\t# this covers ppc64 and aarch64_be only for now\n\tif \[\[ \$\{biendian\}.*?fi\n\n",
        "",
        content,
        count=1,
        flags=re.DOTALL,
    )

    require_contains(content, f'LINUX_T2_PATCHES_VER="{sha}"', "t2linux patch SHA")
    require_contains(content, "linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz", "t2linux SRC_URI")
    require_contains(content, 'eapply "${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}"', "t2linux eapply")
    require_contains(content, '"${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}/extra_config"', "t2linux extra_config")
    require_contains(content, 'KEYWORDS="~amd64"', "restricted KEYWORDS")
    return content


def process_ebuild(upstream_filename, sha):
    content = get_codeberg_raw_file("sys-kernel/gentoo-kernel", upstream_filename)
    return transform_ebuild(content, sha)


def transform_virtual(content):
    content = replace_once(content, r'KEYWORDS=".*?"', 'KEYWORDS="~amd64"', "virtual KEYWORDS")
    content = replace_once(
        content,
        r"(^[ \t]*\|\| \(\n)",
        r"\1\t\t~sys-kernel/t2gentoo-kernel-${PV}\n",
        "virtual dist-kernel dependency alternatives",
        flags=re.MULTILINE,
    )
    require_contains(content, "~sys-kernel/t2gentoo-kernel-${PV}", "t2gentoo virtual dependency")
    return content


def render_virtual(upstream_virtual_filename):
    content = get_codeberg_raw_file("virtual/dist-kernel", upstream_virtual_filename)
    return transform_virtual(content)


def write_virtual(content, virtual_dir, target_version):
    virtual_path = os.path.join(virtual_dir, f"dist-kernel-{target_version}.ebuild")
    os.makedirs(virtual_dir, exist_ok=True)
    with open(virtual_path, "w", encoding="utf-8") as handle:
        handle.write(content)
    return virtual_path


def process_virtual(upstream_virtual_filename, virtual_dir, target_version):
    return write_virtual(render_virtual(upstream_virtual_filename), virtual_dir, target_version)


def find_existing_ebuilds(package_dir, package, base_version):
    paths = glob.glob(os.path.join(package_dir, f"{package}-{base_version}*.ebuild"))
    matches = []
    for path in paths:
        version = get_ebuild_version(path, package)
        base, _revision = split_ebuild_revision(version)
        if base == base_version:
            matches.append(path)
    return matches


def read_current_t2_sha(ebuild_path):
    with open(ebuild_path, "r", encoding="utf-8") as handle:
        for line in handle:
            match = re.match(r'LINUX_T2_PATCHES_VER="([^"]+)"', line)
            if match:
                return match.group(1)
    return None


def select_target_version(kernel_dir, upstream_version, sha):
    upstream_base, upstream_revision = split_ebuild_revision(upstream_version)
    existing_ebuilds = find_existing_ebuilds(
        kernel_dir, "t2gentoo-kernel", upstream_base
    )

    if not existing_ebuilds:
        return format_ebuild_version(upstream_base, upstream_revision), True, None

    latest_existing = max(
        existing_ebuilds,
        key=lambda path: parse_version_key(
            get_ebuild_version(path, "t2gentoo-kernel")
        ),
    )
    latest_version = get_ebuild_version(latest_existing, "t2gentoo-kernel")
    _latest_base, latest_revision = split_ebuild_revision(latest_version)
    current_sha = read_current_t2_sha(latest_existing)

    if latest_revision < upstream_revision:
        return format_ebuild_version(upstream_base, upstream_revision), True, current_sha
    if current_sha != sha:
        return format_ebuild_version(upstream_base, latest_revision + 1), True, current_sha
    return latest_version, False, current_sha


def find_upstream_virtual(virt_files, branch, upstream_version):
    upstream_virtual_filename = f"dist-kernel-{upstream_version}.ebuild"
    if upstream_virtual_filename in virt_files:
        return upstream_virtual_filename
    return get_highest_branch_ebuild(virt_files, "dist-kernel", branch)


def process_branch(branch, kernel_dir, virtual_dir):
    logging.info("Processing branch %s", branch)
    sha = get_latest_t2_sha(branch)

    upstream_ebuild = get_highest_gentoo_version(branch)
    if not upstream_ebuild:
        raise UpdateError(f"Could not find gentoo-kernel for branch {branch}")

    upstream_version = get_ebuild_version(upstream_ebuild, "gentoo-kernel")
    target_version, needs_update, current_sha = select_target_version(
        kernel_dir, upstream_version, sha
    )

    if not needs_update:
        logging.info("Branch %s is up to date.", branch)
        return None

    target_file = os.path.join(kernel_dir, f"t2gentoo-kernel-{target_version}.ebuild")
    logging.info(
        "Updating %s to %s with SHA %s",
        branch,
        os.path.basename(target_file),
        sha,
    )
    if current_sha and current_sha != sha:
        logging.info("Previous t2linux patch SHA for %s was %s", branch, current_sha)

    virt_files = get_codeberg_dir_files("virtual/dist-kernel")
    upstream_virtual_filename = find_upstream_virtual(
        virt_files, branch, upstream_version
    )
    if not upstream_virtual_filename:
        raise UpdateError(f"Could not find upstream virtual/dist-kernel for {branch}")

    content = process_ebuild(upstream_ebuild, sha)
    virtual_content = render_virtual(upstream_virtual_filename)

    with open(target_file, "w", encoding="utf-8") as handle:
        handle.write(content)
    virt_path = write_virtual(virtual_content, virtual_dir, target_version)

    env = os.environ.copy()
    subprocess.run(["ebuild", target_file, "manifest"], check=True, env=env)
    subprocess.run(["ebuild", virt_path, "manifest"], check=True, env=env)

    return f"Update {branch}: {os.path.basename(target_file)} (t2-patch SHA: {sha[:8]})"


def write_commit_message(updates_made):
    with open(os.path.join(OVERLAY_DIR, "commit_message.txt"), "w", encoding="utf-8") as handle:
        handle.write("Auto-update t2gentoo-kernel ebuilds\n\n")
        for update in updates_made:
            handle.write(f"- {update}\n")
    logging.info("Wrote commit_message.txt with update details.")


def main(branches=None):
    kernel_dir = os.path.join(OVERLAY_DIR, "sys-kernel", "t2gentoo-kernel")
    virtual_dir = os.path.join(OVERLAY_DIR, "virtual", "dist-kernel")
    os.makedirs(kernel_dir, exist_ok=True)

    updates_made = []
    errors = []
    if branches is None:
        branches = get_configured_branches()

    for branch in branches:
        update = None
        try:
            update = process_branch(branch, kernel_dir, virtual_dir)
        except UpdateError as exc:
            logging.error("Branch %s failed: %s", branch, exc)
            errors.append(f"{branch}: {exc}")
        except subprocess.CalledProcessError as exc:
            command = " ".join(str(part) for part in exc.cmd)
            logging.error("Branch %s failed while running: %s", branch, command)
            errors.append(f"{branch}: command failed: {command}")
        except Exception as exc:
            logging.exception("Branch %s failed unexpectedly", branch)
            errors.append(f"{branch}: unexpected error: {exc}")
        if update:
            updates_made.append(update)

    if errors:
        logging.error("Update failed for %d branch(es):", len(errors))
        for error in errors:
            logging.error("  %s", error)
        return 1

    if updates_made:
        write_commit_message(updates_made)
    return 0


if __name__ == "__main__":
    sys.exit(main())
