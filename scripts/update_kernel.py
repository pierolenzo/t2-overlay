#!/usr/bin/env python3
import os
import re
import subprocess
import glob
import sys
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)


OVERLAY_DIR = os.environ.get("GITHUB_WORKSPACE", os.getcwd())
if OVERLAY_DIR == '/workspace':
    # Running inside docker
    pass
UPSTREAM_DIR = os.path.join(OVERLAY_DIR, "gentoo-upstream")
BRANCHES = os.environ.get("KERNEL_BRANCHES", "6.12 6.18 7.0 7.1").split()

def get_latest_t2_sha(branch):
    try:
        out = subprocess.check_output(['git', 'ls-remote', 'https://github.com/t2linux/linux-t2-patches.git', f'refs/heads/{branch}'])
        if out:
            return out.decode('utf-8').split()[0]
    except subprocess.CalledProcessError:
        pass
    return None

def get_highest_gentoo_version(branch):
    ebuilds = glob.glob(os.path.join(UPSTREAM_DIR, 'sys-kernel', 'gentoo-kernel', f'gentoo-kernel-{branch}.*.ebuild'))
    if not ebuilds:
        return None
    
    def parse_ver(p):
        v = os.path.basename(p)[14:-7] # remove gentoo-kernel- and .ebuild
        parts = v.split('_p')
        base = parts[0].split('.')
        base = [int(x) for x in base]
        patch = int(parts[1]) if len(parts) > 1 else 0
        return (base, patch)
    
    ebuilds.sort(key=parse_ver)
    return ebuilds[-1]

def process_ebuild(upstream_path, target_dir, sha):
    with open(upstream_path, 'r') as f:
        content = f.read()

    # Apply transformations
    content = re.sub(r'KEYWORDS=".*?"', 'KEYWORDS="~amd64"', content)
    content = re.sub(r'REQUIRED_USE="[^"]*"', '', content)
    content = re.sub(r'(GENTOO_CONFIG_P=.*?)\n', r'\1\nLINUX_T2_PATCHES_VER="' + sha + r'"\n', content)
    
    replacement = '\thttps://github.com/t2linux/linux-t2-patches/archive/${LINUX_T2_PATCHES_VER}.tar.gz\n\t\t\t-> linux-t2-patches-${LINUX_T2_PATCHES_VER}.tar.gz\n\t\\1'
    content = re.sub(r'(verify-sig\? \()', replacement, content)
    
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

def process_virtual(upstream_virtual_path, virtual_dir, target_version):
    with open(upstream_virtual_path, 'r') as f:
        content = f.read()
        
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
            
        version = os.path.basename(upstream_ebuild)[14:-7]
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
            with open(target_file, 'w') as f:
                f.write(content)
                
            virt_target_version = os.path.basename(target_file)[16:-7]
            upstream_virtual_path = os.path.join(UPSTREAM_DIR, 'virtual', 'dist-kernel', f"dist-kernel-{version}.ebuild")
            if not os.path.exists(upstream_virtual_path):
                # Fallback if gentoo removed exact version, find highest in branch
                virt_ebuilds = glob.glob(os.path.join(UPSTREAM_DIR, 'virtual', 'dist-kernel', f'dist-kernel-{branch}.*.ebuild'))
                if virt_ebuilds:
                    virt_ebuilds.sort()
                    upstream_virtual_path = virt_ebuilds[-1]
            
            if os.path.exists(upstream_virtual_path):
                virt_path = process_virtual(upstream_virtual_path, virtual_dir, virt_target_version)
            else:
                logging.warning(f"Could not find upstream virtual for {version}")
                virt_path = None
            
            # Use gentoo-upstream repo as the default repo to resolve eclasses
            env = os.environ.copy()
            # Generate manifests
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
