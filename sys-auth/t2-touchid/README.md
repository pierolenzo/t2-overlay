# Apple T2 Touch ID (`t2-touchid`) on Gentoo Linux

This directory provides Gentoo Portage packaging files (ebuilds and service units) to install and configure **t2-touchid**, supporting both **systemd** and **OpenRC** environments.

---

## 1. How `t2-touchid` Works

On Apple T2 Macs (MacBook Pro 2018–2020, MacBook Air 2018–2020, Mac mini 2018, etc.), the **Touch ID** biometric sensor is not directly connected to the host x86_64 bus. Instead, it is managed exclusively by the T2 chip's Secure Enclave Processor (SEP) inside bridgeOS.

Communication between Linux and the T2 occurs over an internal virtual USB Ethernet link (**USB CDC-NCM**, device ID `05ac:8233`, fixed MAC `AC:DE:48:00:11:22`) using the **BridgeXPC / RemoteXPC** protocol over **IPv6 link-local** addresses.

### Authentication flow:
1. `fprintd` (the standard Linux fingerprint daemon) cannot make network connections directly because its system unit enforces sandboxing (`RestrictAddressFamilies=AF_UNIX AF_LOCAL AF_NETLINK`).
2. `t2-touchid` acts as a local **bridge**:
   - `libfprint` includes a virtual driver (`virtual_device_storage`) that listens on a local Unix socket (`/run/t2-touchid/fprint.sock`) whenever the environment variable `FP_VIRTUAL_DEVICE_STORAGE` is defined.
   - When an application requests biometric verification (e.g. `sudo` or PAM login), `fprintd` opens the Unix socket.
   - `t2-touchid` detects the open socket and commands the T2 SEP sensor over IPv6 to enter match mode.
   - The T2 SEP performs on-chip template matching and returns the verdict to `t2-touchid`.
   - `t2-touchid` feeds the match result back to `fprintd` over the Unix socket as a local scan event (`SCAN <UUID>`).
   - A D-Bus signal is emitted on `org.kait2en.TouchId` so that Touch Bar daemons can display unlock animations.
   - Standard, unpatched `fprintd`, `libfprint`, and `pam_fprintd` are used throughout the entire system.

---

## 2. Requirements & Dependencies

### 2.1 Linux Kernel Configuration
The ebuild automatically inspects your active kernel configuration (via `/proc/config.gz` or `/usr/src/linux/.config`) using Gentoo's standard `linux-info.eclass`.

Ensure the following kernel options are enabled:
* `CONFIG_USB_NET_DRIVERS=y`
* `CONFIG_USB_USBNET=y`
* `CONFIG_USB_NET_CDC_NCM=y` (or `=m`): driver for the internal Apple T2 USB Ethernet interface (`05ac:8233`).
* `CONFIG_IPV6=y`: mandatory; communication with the SEP occurs exclusively over IPv6 link-local addresses.

If any required driver is missing, Portage will warn you during the `pkg_pretend` and `pkg_setup` phases.

### 2.2 Build Dependencies (BDEPEND)
* `dev-lang/rust` or `virtual/rust` with `cargo` (Rust edition 2024 support required).
* `virtual/pkgconfig`.

### 2.3 Runtime Dependencies (RDEPEND)
* `sys-auth/fprintd` (with PAM support enabled).
* `sys-auth/libfprint` (**CRITICAL: see Section 3**).
* `net-misc/iputils` (provides `ping -6` used for T2 link-local discovery).
* `sys-apps/iproute2` (provides `ip` command used to inspect IPv6 neighbor entries).
* `sys-apps/dbus` (system D-Bus daemon).
* `sys-auth/elogind` or `sys-apps/systemd` (optional via `USE="elogind"` or `USE="systemd"`, used to listen for `PrepareForSleep` signals over D-Bus upon resume).
* `net-misc/networkmanager` (optional, if using NetworkManager with `USE="networkmanager"`).

---

## 3. CRITICAL NOTE ON `sys-auth/libfprint`

In Gentoo, upstream `sys-auth/libfprint` is built by default with Meson flag `-Ddrivers=default`.
The default driver set **omits virtual drivers**, including `virtual_device_storage`. Without this driver, `fprintd` will completely ignore `FP_VIRTUAL_DEVICE_STORAGE` and will report no fingerprint reader found.

An ebuild cannot directly run `emerge` on another package due to Portage's security sandbox. However, two solutions are provided:

### Method A: Automated via Overlay (Recommended)
This repository includes a customized ebuild for `sys-auth/libfprint-1.94.10-r1` in `sys-auth/libfprint/`. It introduces the `virtual-drivers` USE flag (enabled by default with `+virtual-drivers`), which automatically injects `-Ddrivers=all`.

Because `t2-touchid` declares `RDEPEND=">=sys-auth/libfprint-1.94.0[virtual-drivers(+)]"`, simply copying both packages into your local overlay will cause Portage to **automatically rebuild/upgrade `libfprint` with virtual driver support** when you emerge `sys-auth/t2-touchid`!

### Method B: Manual Portage Environment Override
If you prefer to keep the upstream Gentoo ebuild for `libfprint`:
```bash
sudo mkdir -p /etc/portage/env /etc/portage/package.env

# Enable all drivers (including virtual_device_storage)
echo 'myemesonargs=("-Ddrivers=all")' | sudo tee /etc/portage/env/libfprint-virtual

# Assign the environment file to sys-auth/libfprint
echo 'sys-auth/libfprint libfprint-virtual' | sudo tee -a /etc/portage/package.env

# Re-emerge libfprint
sudo emerge --ask --oneshot sys-auth/libfprint
```

> [!NOTE]
> `t2-touchid` includes a `pkg_pretend()` check that verifies at install time whether the installed `libfprint-2.so` contains virtual driver support. It will display a clear warning if `FP_VIRTUAL_DEVICE_STORAGE` is not detected.

---

## 4. Installation via Local Overlay

### Step 4.1: Create a local repository (if you don't already have one)
```bash
sudo mkdir -p /var/db/repos/localrepo/{profiles,metadata}
echo "localrepo" | sudo tee /var/db/repos/localrepo/profiles/repo_name

cat << 'EOF' | sudo tee /etc/portage/repos.conf/localrepo.conf
[localrepo]
location = /var/db/repos/localrepo
masters = gentoo
auto-sync = no
EOF
```

### Step 4.2: Copy ebuild files into your overlay
From the root of this repository:
```bash
# 1. Copy t2-touchid
sudo mkdir -p /var/db/repos/localrepo/sys-auth/t2-touchid
sudo cp -r t2-services/t2-touchid/packaging/gentoo/sys-auth/t2-touchid/* /var/db/repos/localrepo/sys-auth/t2-touchid/

# 2. (Recommended) Copy libfprint to enable automatic rebuild with virtual drivers
sudo mkdir -p /var/db/repos/localrepo/sys-auth/libfprint
sudo cp -r t2-services/t2-touchid/packaging/gentoo/sys-auth/libfprint/* /var/db/repos/localrepo/sys-auth/libfprint/
```

### Step 4.3: Generate Manifest files
```bash
cd /var/db/repos/localrepo/sys-auth/t2-touchid
sudo ebuild t2-touchid-0.1.0.ebuild manifest
# (Or for live git: sudo ebuild t2-touchid-9999.ebuild manifest)

# If you copied libfprint into the overlay:
cd /var/db/repos/localrepo/sys-auth/libfprint
sudo ebuild libfprint-1.94.10-r1.ebuild manifest
```

### Step 4.4: Install the package
```bash
sudo emerge --ask sys-auth/t2-touchid
```
Portage will resolve dependencies and rebuild `sys-auth/libfprint` with virtual driver support if needed.

---

## 5. Apple T2 Network Configuration (CDC-NCM)

The internal CDC-NCM link must be up and assigned an IPv6 link-local address (`fe80:...`).

* **With NetworkManager:**
  When built with `USE="networkmanager"`, the ebuild installs `/etc/NetworkManager/system-connections/t2-ncm.nmconnection`. Reload NetworkManager:
  ```bash
  nmcli connection reload
  nmcli connection up "Apple T2 Bridge"
  ```

* **With systemd-networkd:**
  The ebuild installs `10-t2-ncm.network` into `/usr/lib/systemd/network/10-t2-ncm.network`.
  Restart `systemd-networkd`:
  ```bash
  systemctl restart systemd-networkd
  ```

* **With OpenRC / netifrc:**
  Ensure the CDC-NCM interface (identifiable by MAC address `AC:DE:48:00:11:22` or driver `cdc_ncm`) is brought up (`ip link set <interface> up`). The Linux kernel will automatically generate a link-local IPv6 address (`fe80::...`).

---

## 6. Fingerprint Enrollment & Binding

1. **Enroll fingers in macOS first:**
   Linux cannot directly enroll new fingerprints into the Secure Enclave (Apple uses proprietary biometric enrollment keys and ACM contexts). Enroll your fingers in macOS (System Settings -> Touch ID).
2. **First-unlock biometric keybag gate:**
   After a cold boot or full power reset, the SEP biometric keybag remains locked until unlocked once by entering your macOS account password. Logging into macOS once unlocks the SEP, and this unlocked state persists across reboots into Linux.
3. **Bind to your Linux user account:**
   - In `/etc/kait2en/t2-touchid.conf`, set your Linux username:
     ```sh
     T2_TOUCHID_BIND_USER="your_linux_username"
     ```
   - On its first run, `t2-touchid` will automatically query the T2 SEP and bind the enrolled identities to your Linux user via `fprintd-enroll`.
   - Alternatively, while `t2-touchid` is running, you can manually run:
     ```bash
     fprintd-enroll
     ```

---

## 7. Starting the Service

* **On systemd:**
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable --now kait2en-t2-touchid.service
  sudo systemctl try-restart fprintd.service
  ```

* **On OpenRC:**
  ```bash
  sudo rc-update add t2-touchid default
  sudo rc-service t2-touchid start
  ```

---

## 8. Complementary PAM Configuration (Touch ID + Password Fallback)

Touch ID is configured as **complementary authentication** (`sufficient` control flag). This means:
* You can touch the sensor to authenticate instantly.
* If you press Enter, cancel, or if biometric matching times out, PAM automatically falls back to your regular password prompt.

The package installs a helper script `/usr/sbin/t2-touchid-pam` to safely enable, disable, and check complementary PAM configuration.

### Option 8.1: Using the helper tool (Recommended)
```bash
# Check current PAM status for sudo:
sudo t2-touchid-pam --status sudo

# Enable Touch ID for sudo (safely backups /etc/pam.d/sudo and inserts pam_fprintd.so):
sudo t2-touchid-pam --enable sudo

# Or enable for login/system-auth:
sudo t2-touchid-pam --enable login

# To disable and revert at any time:
sudo t2-touchid-pam --disable sudo
```

### Option 8.2: Manual PAM configuration
If you prefer manual edits, open `/etc/pam.d/sudo` and ensure `pam_fprintd.so` is placed as `sufficient` before `system-auth`:

```pam
#%PAM-1.0
auth        sufficient    pam_fprintd.so
auth        include       system-auth
account     include       system-auth
session     include       system-auth
```

Open a new terminal and test with `sudo -v`. `fprintd` will prompt for your fingerprint, the Touch ID sensor will activate, and pressing Enter or failing the scan will immediately fall back to password entry!
