#!/usr/bin/env python3
import os
import re
import subprocess
import glob
import sys
import logging
import json
import urllib.request

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)

OVERLAY_DIR = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
if OVERLAY_DIR == '/workspace':
    # Running inside docker
    pass
BRANCHES = os.environ.get("KERNEL_BRANCHES", "6.12 6.18 7.0 7.1").split()

_api_cache = {}
def get_codeberg_dir_files(path):
    if path in _api_cache:
        return _api_cache[path]
    url = f"https://codeberg.org/api/v1/repos/gentoo/gentoo/contents/{path}?ref=master"
    req = urllib.request.Request(url)
    try:
        response = urllib.request.urlopen(req)
        data = json.loads(response.read().decode('utf-8'))
        files = [f['name'] for f in data if f['name'].endswith('.ebuild')]
        _api_cache[path] = files
        return files
    except Exception as e:
        logging.error(f"Error fetching API {url}: {e}")
        return []

def get_codeberg_raw_file(path, filename):
    url = f"https://codeberg.org/gentoo/gentoo/raw/branch/master/{path}/{filename}"
    req = urllib.request.Request(url)
    try:
        response = urllib.request.urlopen(req)
        return response.read().decode('utf-8')
    except Exception as e:
        logging.error(f"Error downloading {url}: {e}")
        return None

def get_latest_t2_sha(branch):
    try:
        out = subprocess.check_output(['git', 'ls-remote', 'https://github.com/t2linux/linux-t2-patches.git', f'refs/heads/{branch}'])
        if out:
            return out.decode('utf-8').split()[0]
    except subprocess.CalledProcessError:
        pass
    return None

def get_highest_gentoo_version(branch):
    files = get_codeberg_dir_files('sys-kernel/gentoo-kernel')
    prefix = f"gentoo-kernel-{branch}."
    branch_ebuilds = [f for f in files if f.startswith(prefix)]
    if not branch_ebuilds:
        return None
    
    def parse_ver(p):
        v = p[14:-7] # remove gentoo-kernel- and .ebuild
        parts = v.split('_p')
        base = parts[0].split('.')
        base = [int(x) for x in base]
        patch = int(parts[1]) if len(parts) > 1 else 0
        return (base, patch)
    
    branch_ebuilds.sort(key=parse_ver)
    return branch_ebuilds[-1]

def process_ebuild(upstream_filename, target_dir, sha):
    content = get_codeberg_raw_file('sys-kernel/gentoo-kernel', upstream_filename)
    if not content:
        return None

    # Apply transformations
    content = re.sub(r'KEYWORDS=".*?"', 'KEYWORDS="~amd64"', content)
    content = re.sub(r'REQUIRED_USE="[^"]*"', '', content)
    content = re.sub(r'(GENTOO_CONFIG_P=.*?)\n', r'\1\nLINUX_T2_PATCHES_VER="' + sha + r'"\n', content)
    
    # Inject t2linux patches URL strictly into SRC_URI before the verify-sig block
    replacement = '\thttps://github.com/t2linux/linux-t2-patches/archive/${LINUX_T2_PATCHES_VER}.tar.gz\n\t\t\t-> linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz\n\\1'
    content = re.sub(r'(\n[ \t]*verify-sig\? \(\n[ \t]*https://cdn\.kernel\.org/pub/linux/kernel/)', replacement, content)
    
    content = re.sub(r'https://www.kernel.org/', 'https://www.kernel.org/\n\thttps://t2linux.org/', content)
    content = re.sub(r'DESCRIPTION="Linux kernel built with Gentoo patches"', 'DESCRIPTION="Linux kernel built with Gentoo patches and t2linux patches"', content)
    
    case_regex = r'case \$\{ARCH\} in.*?esac'
    replacement_case = '''case ${ARCH} in
\t\tamd64)
\t\t\tcp "${WORKDIR}/kernel-${CONFIG_VER}/kernel-x86_64-fedora.config" .config || die
\t\t\t;;
\t\t*)
\t\t\tdie "Unsupported arch ${ARCH}"
\t\t\t;;
\tesac'''
    content = re.sub(case_regex, replacement_case, content, flags=re.DOTALL)
    
    content = re.sub(r'(eapply "\$\{WORKDIR\}/\$\{PATCHSET\}".*?\n)', r'\1\teapply "${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}"\n', content)
    content = re.sub(r'myversion="-gentoo-dist"', 'myversion="-t2gentoo-dist"', content)
    content = re.sub(r'("\$\{dist_conf_path\}"/6\.12\+\.config)', r'\1\n\t\t"${WORKDIR}/linux-t2-patches-${LINUX_T2_PATCHES_VER}/extra_config"', content)
    
    content = re.sub(r'\tlocal biendian=false\n', '', content)
    content = re.sub(r'\t# this covers ppc64 and aarch64_be only for now\n\tif \[\[ \$\{biendian\}.*?fi\n\n', '', content, flags=re.DOTALL)
    
    return content

def process_virtual(upstream_virtual_filename, virtual_dir, target_version):
    content = get_codeberg_raw_file('virtual/dist-kernel', upstream_virtual_filename)
    if not content:
        return None
        
    # Restrict architectures
    content = re.sub(r'KEYWORDS=".*?"', 'KEYWORDS="~amd64"', content)
    
    # Inject t2gentoo-kernel into RDEPEND
    content = re.sub(r'(\|\s*\(\s*)', r'\1\n\t\t~sys-kernel/t2gentoo-kernel-${PV}', content)
    
    virtual_path = os.path.join(virtual_dir, f"dist-kernel-{target_version}.ebuild")
    os.makedirs(virtual_dir, exist_ok=True)
    with open(virtual_path, 'w') as f:
        f.write(content)
    return virtual_path

def main():
    kernel_dir = os.path.join(OVERLAY_DIR, 'sys-kernel', 't2gentoo-kernel')
    virtual_dir = os.path.join(OVERLAY_DIR, 'virtual', 'dist-kernel')
    os.makedirs(kernel_dir, exist_ok=True)
    
    updates_made = []
    
    for branch in BRANCHES:
        logging.info(f"Processing branch {branch}")
        sha = get_latest_t2_sha(branch)
        if not sha:
            logging.warning(f"Could not get SHA for branch {branch}")
            continue
            
        upstream_ebuild = get_highest_gentoo_version(branch)
        if not upstream_ebuild:
            logging.warning(f"Could not find gentoo-kernel for branch {branch}")
            continue
            
        version = upstream_ebuild[14:-7]
        target_ebuild_name = f"t2gentoo-kernel-{version}.ebuild"
        
        target_path = os.path.join(kernel_dir, target_ebuild_name)
        existing_ebuilds = glob.glob(os.path.join(kernel_dir, f"t2gentoo-kernel-{version}*.ebuild"))
        
        current_sha = None
        target_file = target_path
        if existing_ebuilds:
            def get_rev(p):
                if '-r' in p:
                    return int(p.split('-r')[-1].replace('.ebuild', ''))
                return 0
            existing_ebuilds.sort(key=get_rev)
            latest_existing = existing_ebuilds[-1]
            target_file = latest_existing
            with open(latest_existing, 'r') as f:
                for line in f:
                    if line.startswith('LINUX_T2_PATCHES_VER='):
                        current_sha = line.split('"')[1]
                        break
        
        needs_update = False
        if not existing_ebuilds:
            needs_update = True
        elif current_sha != sha:
            needs_update = True
            rev = 1
            if '-r' in target_file:
                rev = int(target_file.split('-r')[-1].replace('.ebuild', '')) + 1
            target_file = os.path.join(kernel_dir, f"t2gentoo-kernel-{version}-r{rev}.ebuild")
            
        if needs_update:
            logging.info(f"Updating {branch} to {os.path.basename(target_file)} with SHA {sha}")
            updates_made.append(f"Update {branch}: {os.path.basename(target_file)} (t2-patch SHA: {sha[:8]})")
            content = process_ebuild(upstream_ebuild, kernel_dir, sha)
            if not content:
                logging.error(f"Failed to process ebuild {upstream_ebuild}")
                continue
            with open(target_file, 'w') as f:
                f.write(content)
                
            virt_target_version = os.path.basename(target_file)[16:-7]
            
            # Find the correct virtual ebuild
            virt_files = get_codeberg_dir_files('virtual/dist-kernel')
            upstream_virtual_filename = f"dist-kernel-{version}.ebuild"
            if upstream_virtual_filename not in virt_files:
                # Fallback if gentoo removed exact version, find highest in branch
                branch_virt_ebuilds = [f for f in virt_files if f.startswith(f"dist-kernel-{branch}.")]
                if branch_virt_ebuilds:
                    branch_virt_ebuilds.sort()
                    upstream_virtual_filename = branch_virt_ebuilds[-1]
                else:
                    upstream_virtual_filename = None
            
            virt_path = None
            if upstream_virtual_filename:
                virt_path = process_virtual(upstream_virtual_filename, virtual_dir, virt_target_version)
            else:
                logging.warning(f"Could not find upstream virtual for {version}")
            
            env = os.environ.copy()
            subprocess.run(['ebuild', target_file, 'manifest'], check=True, env=env)
            if virt_path:
                subprocess.run(['ebuild', virt_path, 'manifest'], check=True, env=env)
        else:
            logging.info(f"Branch {branch} is up to date.")
            
    if updates_made:
        with open(os.path.join(OVERLAY_DIR, 'commit_message.txt'), 'w') as f:
            f.write("Auto-update t2gentoo-kernel ebuilds\n\n")
            for u in updates_made:
                f.write(f"- {u}\n")
        logging.info("Wrote commit_message.txt with update details.")
            
if __name__ == '__main__':
    main()
